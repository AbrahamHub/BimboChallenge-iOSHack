import SwiftUI

/// Colores y tokens compartidos (Ruta, Stock, detalle de parada).
enum AppPalette {
    static let navy = Color(red: 3.0 / 255.0, green: 24.0 / 255.0, blue: 80.0 / 255.0)
    static let brandRed = Color(red: 226.0 / 255.0, green: 27.0 / 255.0, blue: 26.0 / 255.0)
    static let background = Color(red: 245.0 / 255.0, green: 247.0 / 255.0, blue: 252.0 / 255.0)
    static let lineYellow = Color(red: 255.0 / 255.0, green: 199.0 / 255.0, blue: 44.0 / 255.0)
    /// Cantidad “normal” en lista de inventario (azul medio).
    static let stockQuantity = Color(red: 64.0 / 255.0, green: 95.0 / 255.0, blue: 180.0 / 255.0)
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
