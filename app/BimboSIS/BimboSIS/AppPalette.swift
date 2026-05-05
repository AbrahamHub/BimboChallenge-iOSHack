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
    /// Tamaño del cuadrado blanco (la referencia de **Mi Ruta** usa ~64 pt).
    var size: CGFloat = 48
    var action: () -> Void

    private var cornerRadius: CGFloat { size * (14.0 / 48.0) }

    var body: some View {
        Button(action: action) {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(.white)
                .frame(width: size, height: size)
                .overlay {
                    Text("B")
                        .font(.system(size: size * 0.48, weight: .heavy, design: .rounded))
                        .foregroundStyle(AppPalette.brandRed)
                }
        }
        .buttonStyle(.plain)
    }
}

/// Insignia tipo cápsula **OFFLINE** (punto amarillo) sobre el logo Bimbo.
private struct OfflineIndicatorBadge: View {
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(AppPalette.lineYellow)
                .frame(width: 8, height: 8)

            Text("OFFLINE")
                .font(.caption2.weight(.heavy))
                .tracking(0.55)
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color(red: 52.0 / 255.0, green: 62.0 / 255.0, blue: 98.0 / 255.0))
        .clipShape(Capsule())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("Sin conexión"))
    }
}

/// Logo de marca con indicador offline encima cuando no hay red.
struct BrandLogoToolbarCluster: View {
    @EnvironmentObject private var connectivity: ConnectivityViewModel
    var logoSize: CGFloat = 48
    var signOutAction: () -> Void

    var body: some View {
        VStack(spacing: 6) {
            if connectivity.isOffline {
                OfflineIndicatorBadge()
            }
            BrandLogoButton(size: logoSize, action: signOutAction)
        }
    }
}

/// SF Symbols por SKU demo (pan, integral, donas, etc.) para listas de stock / rotación / confirmación.
enum BimboDemoProductSymbol {
    /// Nombres **SF Symbols** estables (iOS 15+) para que el ícono siempre resuelva en runtime.
    static func systemImage(forSKU sku: String) -> String {
        switch sku {
        case "SKU BIM-001": return "bag.fill"
        case "SKU BIM-002": return "leaf.fill"
        case "SKU BIM-003": return "square.stack.fill"
        case "SKU BIM-004": return "moon.stars.fill"
        case "SKU BIM-005": return "seal.fill"
        case "SKU BIM-006": return "flame.fill"
        case "SKU BIM-007": return "square.grid.2x2.fill"
        case "SKU BIM-008": return "snowflake"
        default: return "shippingbox.fill"
        }
    }
}
