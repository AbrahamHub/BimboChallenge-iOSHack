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

/// Tarjeta de producto con stepper − / cantidad / + (misma lógica visual que rotación de stock).
struct BimboStepperProductCard: View {
    let title: String
    /// Texto secundario bajo el nombre (p. ej. cantidad en piezas).
    let detail: String
    @Binding var quantity: Int
    let maxQuantity: Int
    /// Si `true`, muestra el placeholder tipo mock `[ÍCONO]` con borde punteado.
    var useIconPlaceholder: Bool = false

    private var canIncrement: Bool { quantity < maxQuantity }
    private var canDecrement: Bool { quantity > 0 }

    var body: some View {
        HStack(spacing: 12) {
            Group {
                if useIconPlaceholder {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Color.gray.opacity(0.45), style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
                        .frame(width: 52, height: 52)
                        .overlay {
                            Text("[ÍCONO]")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(Color.gray.opacity(0.55))
                        }
                } else {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.gray.opacity(0.22), lineWidth: 1)
                        .frame(width: 52, height: 52)
                        .overlay {
                            Image(systemName: "photo")
                                .foregroundStyle(.tertiary)
                        }
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(AppPalette.navy)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)

                Text(detail)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            HStack(spacing: 10) {
                Button {
                    guard canDecrement else { return }
                    quantity -= 1
                } label: {
                    Circle()
                        .fill(Color.gray.opacity(canDecrement ? 0.22 : 0.12))
                        .frame(width: 36, height: 36)
                        .overlay {
                            Image(systemName: "minus")
                                .font(.body.weight(.bold))
                                .foregroundStyle(canDecrement ? AppPalette.mutedButtonForeground : Color.gray.opacity(0.35))
                        }
                }
                .buttonStyle(.plain)
                .disabled(!canDecrement)

                Text("\(quantity)")
                    .font(.title3.weight(.bold))
                    .monospacedDigit()
                    .frame(minWidth: 26)
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.15), value: quantity)

                Button {
                    guard canIncrement else { return }
                    quantity += 1
                } label: {
                    Circle()
                        .fill(canIncrement ? AppPalette.navy : Color.gray.opacity(0.35))
                        .frame(width: 36, height: 36)
                        .overlay {
                            Image(systemName: "plus")
                                .font(.body.weight(.bold))
                                .foregroundStyle(.white.opacity(canIncrement ? 1 : 0.55))
                        }
                }
                .buttonStyle(.plain)
                .disabled(!canIncrement)
            }
        }
        .padding(12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.gray.opacity(0.14), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("\(title), \(quantity) piezas de \(maxQuantity) máximo"))
    }
}
