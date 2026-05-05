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

actor FirebaseAILogicService {
    static let shared = FirebaseAILogicService()
    
    private let storage = Storage.storage()
    private let db = Firestore.firestore()
    private let vertex = VertexAI.vertexAI()
    
    private init() {}
    
    /// Procesamiento completo del pipeline requerido
    func processShelfImage(imageData: Data) async throws -> StructuredShelfResult {
        // 1. Subir imagen optimizada a Firebase Storage
        let imageId = UUID().uuidString
        let storageRef = storage.reference().child("shelves/\(imageId).jpg")
        
        do {
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"
            _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
        } catch {
            throw FirebaseAIError.uploadFailed(error)
        }
        
        let gsUri = "gs://\(storageRef.bucket)/\(storageRef.fullPath)"
        
        // 2. Enviar imagen a Firebase AI Logic (Vertex AI)
        let model = vertex.generativeModel(
            modelName: "gemini-1.5-flash",
            generationConfig: GenerationConfig(responseMIMEType: "application/json")
        )
        
        let prompt = """
        Analiza esta imagen de un anaquel de pan Bimbo.
        Devuelve un objeto JSON estrictamente con la siguiente estructura:
        {
            "products": ["lista", "de", "nombres", "de", "productos"],
            "total_visible_products": 0,
            "low_stock_products": ["lista", "de", "productos", "con", "poco", "inventario"],
            "fifo_priority": ["lista", "de", "productos", "que", "deben", "rotarse"],
            "shelf_health_score": 0 al 100
        }
        Asegúrate de que la respuesta sea un JSON válido.
        """
        
        let imageForAI = UIImage(data: imageData) ?? UIImage()
        
        let resultJSON: String
        do {
            let response = try await model.generateContent(prompt, imageForAI)
            guard let text = response.text else {
                throw FirebaseAIError.invalidResponse
            }
            resultJSON = text
        } catch {
            throw FirebaseAIError.analysisFailed(error)
        }
        
        // 3. Recibir JSON estructurado y decodificar
        guard let jsonData = resultJSON.data(using: .utf8),
              let structuredResult = try? JSONDecoder().decode(StructuredShelfResult.self, from: jsonData) else {
            throw FirebaseAIError.invalidResponse
        }
        
        // 4. Guardar resultado en Firestore
        do {
            var docData = try JSONEncoder().encode(structuredResult)
            var dict = try JSONSerialization.jsonObject(with: docData, options: []) as? [String: Any] ?? [:]
            dict["timestamp"] = FieldValue.serverTimestamp()
            dict["storage_uri"] = gsUri
            dict["id"] = imageId
            
            try await db.collection("shelf_scans").document(imageId).setData(dict)
        } catch {
            // Manejo offline/caché aquí: Firestore guarda offline por defecto,
            // pero si falla localmente, reportamos.
            throw FirebaseAIError.firestoreFailed(error)
        }
        
        return structuredResult
    }
}
