import Foundation
import SwiftUI
import UIKit

@MainActor
class ShelfAnalysisViewModel: ObservableObject {
    enum State: Equatable {
        case idle
        case processing
        case success(StructuredShelfResult)
        case error(String)
        
        static func == (lhs: State, rhs: State) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle), (.processing, .processing):
                return true
            case (.success, .success):
                return true // Simplificado
            case (.error(let a), .error(let b)):
                return a == b
            default:
                return false
            }
        }
    }
    
    @Published var state: State = .idle
    @Published var progressMessage: String = ""
    
    func analyzeImage(_ image: UIImage) {
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            self.state = .error("Error al comprimir imagen")
            return
        }
        
        state = .processing
        progressMessage = "Preparando análisis..."
        
        Task {
            let maxRetries = 3
            for attempt in 1...maxRetries {
                do {
                    progressMessage = "Subiendo imagen y analizando con IA..."
                    let result = try await FirebaseAILogicService.shared.processShelfImage(imageData: data)
                    
                    self.state = .success(result)
                    return // Exito
                } catch {
                    print("Intento \(attempt) fallido: \(error)")
                    if attempt == maxRetries {
                        self.state = .error("Falló el análisis tras \(maxRetries) intentos. Revisa tu conexión.")
                    } else {
                        progressMessage = "Reintentando (\(attempt)/\(maxRetries))..."
                        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 segundos
                    }
                }
            }
        }
    }
    
    func reset() {
        state = .idle
        progressMessage = ""
    }
}
