import SwiftUI

/// Tokens visuales de referencia (alineados con **Mi Ruta**).
enum BimboLayout {
    /// Altura del bloque navy en pantallas principales sin tarjeta flotante.
    static let heroHeaderHeight: CGFloat = 190
    static let heroCornerRadius: CGFloat = 28
    static let heroHorizontalPadding: CGFloat = 20
    static let heroTopPadding: CGFloat = 52
    static let titleSize: CGFloat = 36
}

/// Cabecera hero navy como la primera pantalla (título grande rounded + subtítulo + trailing).
struct ScreenHeroHeader<Trailing: View>: View {
    let title: String
    let subtitle: String
    var navyHeight: CGFloat = BimboLayout.heroHeaderHeight

    @ViewBuilder let trailing: () -> Trailing

    var body: some View {
        ZStack(alignment: .topTrailing) {
            AppPalette.navy
                .frame(height: navyHeight)
                .clipShape(RoundedRectangle(cornerRadius: BimboLayout.heroCornerRadius, style: .continuous))
                .ignoresSafeArea(edges: .top)

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: BimboLayout.titleSize, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text(subtitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.85))
                }

                Spacer(minLength: 8)

                trailing()
            }
            .padding(.horizontal, BimboLayout.heroHorizontalPadding)
            .padding(.top, BimboLayout.heroTopPadding)
        }
    }
}

/// Campo de búsqueda tipo Stock / modal rotación (SF Symbol estándar de sistema).
struct BimboSearchField: View {
    @Binding var text: String
    var placeholder: String = "Buscar producto o SKU"

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.body.weight(.semibold))
                .foregroundStyle(.secondary)
                .symbolRenderingMode(.hierarchical)

            TextField(placeholder, text: $text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(AppPalette.secondaryButtonFill.opacity(0.98))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

/// Ícono de barra estilo Apple: SF Symbol escalado y área mínima de toque (~44).
struct ToolbarSFIconButton: View {
    let systemName: String
    var fontSize: CGFloat = 26
    var foreground: Color = AppPalette.navy
    var accessibilityLabelText: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: fontSize, weight: .semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(foreground)
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(accessibilityLabelText))
    }
}
