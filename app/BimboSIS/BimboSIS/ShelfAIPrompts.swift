import Foundation

/**
 * SISTEMA MODULAR DE PROMPTS - BIMBO AI LOGIC
 * Optimizado para: Estabilidad JSON, Velocidad y Bajo Consumo de Tokens.
 */

struct ShelfAIPrompts {
    
    // MARK: - 1. Catálogo de Productos (Grounding)
    static let productCatalog = [
        "pan_blanco", "pan_integral", "bimbollos", "nito", "pinguino",
        "roles_canela", "panque_hersheys", "mantecadas", "donas_glase", "rebanadas"
    ]
    
    // MARK: - 2. Módulo: Análisis Visual y Conteo (Multimodal)
    struct VisualAnalysis {
        static let systemPrompt = """
        Eres un experto en auditoría de anaqueles para Bimbo. 
        Tu tarea es identificar productos y contar existencias.
        REGLAS CRÍTICAS:
        1. Solo usa SKUs del catálogo proporcionado.
        2. Si un producto es ambiguo, clasifícalo como el SKU más cercano.
        3. Devuelve ÚNICAMENTE un JSON válido.
        """
        
        static func userPrompt(catalog: [String]) -> String {
            return """
            Analiza la imagen del anaquel.
            CATÁLOGO PERMITIDO: [\(catalog.joined(separator: ", "))]
            
            Devuelve un JSON con esta estructura:
            {
              "inventory": [
                {"sku": "string", "quantity": number, "shelf_level": number}
              ]
            }
            """
        }
        
        static let jsonSchema = """
        {
          "type": "object",
          "properties": {
            "inventory": {
              "type": "array",
              "items": {
                "type": "object",
                "properties": {
                  "sku": { "type": "string" },
                  "quantity": { "type": "integer" },
                  "shelf_level": { "type": "integer" }
                },
                "required": ["sku", "quantity", "shelf_level"]
              }
            }
          },
          "required": ["inventory"]
        }
        """
    }
    
    // MARK: - 3. Módulo: Lógica FIFO y Salud del Anaquel (Text-only)
    struct ShelfIntelligence {
        static let systemPrompt = """
        Eres un motor de reglas de negocio para distribución logística.
        Analizas datos de inventario para determinar salud del anaquel y prioridad FIFO.
        REGLAS:
        - FIFO Priority: Productos con cantidad < 3 o en niveles inferiores.
        - Shelf Health: 100 base, resta 10 por cada SKU faltante o < 2 unidades.
        """
        
        static func userPrompt(inventoryJSON: String) -> String {
            return """
            Datos de inventario detectado:
            \(inventoryJSON)
            
            Calcula:
            1. shelf_health_score (0-100)
            2. fifo_priority (SKUs que deben moverse al frente)
            3. low_stock_products (SKUs con < 3 unidades)
            
            Responde en JSON:
            {
              "shelf_health_score": number,
              "fifo_priority": ["sku1", "sku2"],
              "low_stock_products": ["sku3"]
            }
            """
        }
    }
    
    // MARK: - 4. Módulo: Recomendaciones Comerciales (Text-only)
    struct Recommendations {
        static let systemPrompt = """
        Eres un asesor de ventas preventa de Bimbo.
        Tu objetivo es maximizar la disponibilidad de productos estrella.
        """
        
        static func userPrompt(intelligenceJSON: String) -> String {
            return """
            Basado en este análisis:
            \(intelligenceJSON)
            
            Genera 3 recomendaciones cortas (máx 10 palabras c/u) para el repartidor.
            Estructura JSON:
            {
              "recommendations": ["string"]
            }
            """
        }
    }
}

// MARK: - Estrategias de Robustez
enum AIProcessingStrategy {
    case multimodalSingleStep // Todo en uno (Rápido, menos preciso)
    case modularPipeline     // Por pasos (Lento, alta precisión, costo optimizado en tokens de texto)
    
    /// Configuración de reintento con backoff exponencial simple
    static func retryConfig(attempt: Int) -> Double {
        return pow(2.0, Double(attempt)) // 2s, 4s, 8s...
    }
}
