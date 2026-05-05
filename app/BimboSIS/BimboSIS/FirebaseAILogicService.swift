import Foundation
import UIKit
import FirebaseStorage
import FirebaseFirestore
import FirebaseVertexAI

struct StructuredShelfResult: Codable {
    let products: [String]
    let total_visible_products: Int
    let low_stock_products: [String]
    let fifo_priority: [String]
    let shelf_health_score: Int
}

enum FirebaseAIError: Error {
    case uploadFailed(Error)
    case analysisFailed(Error)
    case firestoreFailed(Error)
    case invalidResponse
    case timeout
}

// Estructuras internas para el pipeline modular
struct RawInventory: Codable {
    struct Item: Codable {
        let sku: String
        let quantity: Int
        let shelf_level: Int
    }
    let inventory: [Item]
}

actor FirebaseAILogicService {
    static let shared = FirebaseAILogicService()
    
    private let storage = Storage.storage()
    private let db = Firestore.firestore()
    private let vertex = VertexAI.vertexAI()
    
    private init() {}
    
    /// Procesamiento modular del pipeline (Vision -> Intelligence -> Recommendations)
    func processShelfImage(imageData: Data) async throws -> StructuredShelfResult {
        // 1. Subir imagen a Storage
        let imageId = UUID().uuidString
        let gsUri = try await uploadImage(data: imageData, id: imageId)
        
        // 2. MÓDULO 1: Análisis Visual y Conteo (Multimodal)
        let rawInventory = try await performVisualAnalysis(imageData: imageData)
        
        // 3. MÓDULO 2: Inteligencia FIFO y Salud (Text-only)
        let shelfIntelligence = try await performIntelligenceAnalysis(rawInventory: rawInventory)
        
        // 4. Guardar en Firestore
        try await saveResultToFirestore(result: shelfIntelligence, imageId: imageId, gsUri: gsUri)
        
        return shelfIntelligence
    }
    
    // MARK: - Pasos del Pipeline Modular
    
    private func uploadImage(data: Data, id: String) async throws -> String {
        let storageRef = storage.reference().child("shelves/\(id).jpg")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        do {
            _ = try await storageRef.putDataAsync(data, metadata: metadata)
            return "gs://\(storageRef.bucket)/\(storageRef.fullPath)"
        } catch {
            throw FirebaseAIError.uploadFailed(error)
        }
    }
    
    private func performVisualAnalysis(imageData: Data) async throws -> RawInventory {
        let model = vertex.generativeModel(
            modelName: "gemini-1.5-flash",
            generationConfig: GenerationConfig(responseMIMEType: "application/json"),
            systemInstruction: ModelContent(role: "system", parts: ShelfAIPrompts.VisualAnalysis.systemPrompt)
        )
        
        let prompt = ShelfAIPrompts.VisualAnalysis.userPrompt(catalog: ShelfAIPrompts.productCatalog)
        let image = UIImage(data: imageData) ?? UIImage()
        
        return try await retryOperation(maxAttempts: 3) {
            let response = try await model.generateContent(prompt, image)
            guard let text = response.text, let data = text.data(using: .utf8) else {
                throw FirebaseAIError.invalidResponse
            }
            return try JSONDecoder().decode(RawInventory.self, from: data)
        }
    }
    
    private func performIntelligenceAnalysis(rawInventory: RawInventory) async throws -> StructuredShelfResult {
        let model = vertex.generativeModel(
            modelName: "gemini-1.5-flash",
            generationConfig: GenerationConfig(responseMIMEType: "application/json"),
            systemInstruction: ModelContent(role: "system", parts: ShelfAIPrompts.ShelfIntelligence.systemPrompt)
        )
        
        let inventoryString = (try? String(data: JSONEncoder().encode(rawInventory), encoding: .utf8)) ?? "{}"
        let prompt = ShelfAIPrompts.ShelfIntelligence.userPrompt(inventoryJSON: inventoryString)
        
        return try await retryOperation(maxAttempts: 2) {
            let response = try await model.generateContent(prompt)
            guard let text = response.text, let data = text.data(using: .utf8) else {
                throw FirebaseAIError.invalidResponse
            }
            
            // Mapeamos el resultado modular al modelo de la App
            struct IntelligenceResult: Codable {
                let shelf_health_score: Int
                let fifo_priority: [String]
                let low_stock_products: [String]
            }
            
            let intel = try JSONDecoder().decode(IntelligenceResult.self, from: data)
            
            return StructuredShelfResult(
                products: rawInventory.inventory.map { $0.sku },
                total_visible_products: rawInventory.inventory.reduce(0) { $0 + $1.quantity },
                low_stock_products: intel.low_stock_products,
                fifo_priority: intel.fifo_priority,
                shelf_health_score: intel.shelf_health_score
            )
        }
    }
    
    private func saveResultToFirestore(result: StructuredShelfResult, imageId: String, gsUri: String) async throws {
        do {
            var docData = try JSONEncoder().encode(result)
            var dict = try JSONSerialization.jsonObject(with: docData, options: []) as? [String: Any] ?? [:]
            dict["timestamp"] = FieldValue.serverTimestamp()
            dict["storage_uri"] = gsUri
            dict["id"] = imageId
            
            try await db.collection("shelf_scans").document(imageId).setData(dict)
        } catch {
            throw FirebaseAIError.firestoreFailed(error)
        }
    }
    
    // MARK: - Utilidades
    
    private func retryOperation<T>(maxAttempts: Int, operation: () async throws -> T) async throws -> T {
        var lastError: Error?
        for attempt in 1...maxAttempts {
            do {
                return try await operation()
            } catch {
                lastError = error
                if attempt < maxAttempts {
                    let delay = AIProcessingStrategy.retryConfig(attempt: attempt)
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
        throw lastError ?? FirebaseAIError.analysisFailed(NSError(domain: "AI", code: -1))
    }
}
