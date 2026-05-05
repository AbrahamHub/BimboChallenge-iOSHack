import SwiftUI

/// Colores y tokens compartidos (Ruta, Stock, detalle de parada).
enum AppPalette {
    static let navy = Color(red: 3.0 / 255.0, green: 24.0 / 255.0, blue: 80.0 / 255.0)
    static let brandRed = Color(red: 226.0 / 255.0, green: 27.0 / 255.0, blue: 26.0 / 255.0)
    static let background = Color(red: 245.0 / 255.0, green: 247.0 / 255.0, blue: 252.0 / 255.0)
    static let lineYellow = Color(red: 255.0 / 255.0, green: 199.0 / 255.0, blue: 44.0 / 255.0)
    /// Cantidad “normal” en lista de inventario (azul medio).
    static let stockQuantity = Color(red: 64.0 / 255.0, green: 95.0 / 255.0, blue: 180.0 / 255.0)
    /// Tarjeta de narración / acentos oscuros sobre header.
    static let deepNavy = Color(red: 15.0 / 255.0, green: 42.0 / 255.0, blue: 122.0 / 255.0)
    /// Botón secundario “Productos rotados”.
    static let rotatedProductsBlue = Color(red: 92.0 / 255.0, green: 106.0 / 255.0, blue: 171.0 / 255.0)
    /// Texto secundario en botones tipo “Entrega confirmada”.
    static let mutedButtonForeground = Color(red: 63.0 / 255.0, green: 71.0 / 255.0, blue: 89.0 / 255.0)
    /// Fondo botón secundario (gris claro).
    static let secondaryButtonFill = Color(red: 242.0 / 255.0, green: 244.0 / 255.0, blue: 248.0 / 255.0)

    // MARK: Semáforo entrega (badges cantidad)
    static let semaphoreRedFill = Color(red: 255.0 / 255.0, green: 235.0 / 255.0, blue: 235.0 / 255.0)
    static let semaphoreYellowFill = Color(red: 255.0 / 255.0, green: 246.0 / 255.0, blue: 214.0 / 255.0)
    static let semaphoreGreenFill = Color(red: 226.0 / 255.0, green: 247.0 / 255.0, blue: 231.0 / 255.0)
    static let semaphoreGreenText = Color(red: 21.0 / 255.0, green: 115.0 / 255.0, blue: 62.0 / 255.0)
}

struct BrandLogoButton: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.white)
                .frame(width: 48, height: 48)
                .overlay {
                    Text("B")
                        .font(.title3.weight(.heavy))
                        .foregroundStyle(AppPalette.brandRed)
                }
        }
        .buttonStyle(.plain)
    }
}
