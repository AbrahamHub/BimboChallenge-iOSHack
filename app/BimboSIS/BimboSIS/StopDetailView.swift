import SwiftUI
import UIKit

struct Product: Identifiable {
    let id = UUID()
    let name: String
    let qty: Int
    let accent: Color
}

struct StopDetailView: View {
    let client: Client

    let products: [Product] = [
        Product(name: "Pan Blanco Grande", qty: 12, accent: Color(red: 1.0, green: 0.93, blue: 0.93)),
        Product(name: "Pan Integral", qty: 8, accent: Color(red: 1.0, green: 0.96, blue: 0.84)),
        Product(name: "Bimbolos", qty: 6, accent: Color(red: 1.0, green: 0.96, blue: 0.84))
    ]

    @State private var showCamera = false
    @State private var capturedImage: UIImage? = nil
    @State private var showImagePreview = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                topSection

                VStack(spacing: 12) {
                    sectionTitle

                    ForEach(products) { product in
                        ProductRow(product: product)
                    }

                    primaryActionButton(
                        title: "Productos rotados (4)",
                        icon: "arrow.2.circlepath",
                        background: Color(red: 92 / 255, green: 106 / 255, blue: 171 / 255),
                        foreground: .white
                    ) {
                        // TODO: Navegar al detalle de productos rotados.
                    }

                    primaryActionButton(
                        title: "Entrega confirmada",
                        icon: "checkmark",
                        background: .white,
                        foreground: Color(red: 63 / 255, green: 71 / 255, blue: 89 / 255)
                    ) {
                        // TODO: Confirmar entrega y actualizar estado/stock.
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.gray.opacity(0.12), lineWidth: 1)
                    )

                    primaryActionButton(
                        title: "Escanear anaquel",
                        icon: "camera.viewfinder",
                        trailingIcon: "chevron.right",
                        background: Color(red: 3 / 255, green: 24 / 255, blue: 80 / 255),
                        foreground: .white
                    ) {
                        showCamera = true
                    }
                    .fullScreenCover(isPresented: $showCamera) {
                        ShelfScannerView { image in
                            capturedImage = image
                            showImagePreview = true
                            showCamera = false
                        }
                    }

                    if showImagePreview, let img = capturedImage {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 220)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Color.white.opacity(0.75), lineWidth: 1)
                            )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 24)
                .background(Color.white)
                .clipShape(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                )
                .offset(y: -16)
            }
        }
        .background(Color(red: 246 / 255, green: 248 / 255, blue: 252 / 255).ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    private var topSection: some View {
        ZStack(alignment: .bottom) {
            Color(red: 3 / 255, green: 24 / 255, blue: 80 / 255)
                .frame(height: 278)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))

            VStack(spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("PRÓXIMA PARADA · 2 DE 6")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.86))

                        Text(client.name)
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .minimumScaleFactor(0.75)
                            .lineLimit(1)
                            .foregroundStyle(.white)

                        HStack(spacing: 6) {
                            Image(systemName: "location.fill")
                            Text(client.address)
                        }
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.95))
                    }

                    Spacer()
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(.white)
                        .frame(width: 48, height: 48)
                        .overlay {
                            Text("B")
                                .font(.title3.weight(.heavy))
                                .foregroundStyle(Color(red: 226 / 255, green: 27 / 255, blue: 26 / 255))
                        }
                }

                NarrationCard()
                    .padding(.bottom, -18)
            }
            .padding(.horizontal, 20)
            .padding(.top, 52)
        }
    }

    private var sectionTitle: some View {
        HStack {
            Text("ENTREGAR EN ESTA PARADA")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
                .tracking(0.8)
            Spacer()
        }
        .padding(.top, 2)
    }

    private func primaryActionButton(
        title: String,
        icon: String,
        trailingIcon: String? = nil,
        background: Color,
        foreground: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.headline.weight(.bold))

                Text(title)
                    .font(.headline.weight(.bold))

                Spacer()

                if let trailingIcon {
                    Image(systemName: trailingIcon)
                        .font(.subheadline.weight(.black))
                }
            }
            .foregroundStyle(foreground)
            .padding(.horizontal, 16)
            .padding(.vertical, 15)
            .frame(maxWidth: .infinity)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct NarrationCard: View {
    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(Color(red: 1, green: 59 / 255, blue: 58 / 255))
                .frame(width: 36, height: 36)
                .overlay {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.subheadline.weight(.heavy))
                        .foregroundStyle(.white)
                }

            VStack(alignment: .leading, spacing: 1) {
                Text("Reproduciendo narración")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                Text("Audio automático · 2 repeticiones")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
            }

            Spacer()

            Text("Repetir")
                .font(.caption.weight(.heavy))
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(red: 1, green: 59 / 255, blue: 58 / 255))
                .clipShape(Capsule(style: .continuous))
        }
        .padding(12)
        .background(Color(red: 15 / 255, green: 42 / 255, blue: 122 / 255))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct ProductRow: View {
    let product: Product

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [4]))
                .foregroundStyle(Color(red: 100 / 255, green: 126 / 255, blue: 196 / 255))
                .frame(width: 46, height: 46)
                .overlay {
                    Text("ÍCONO")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(Color(red: 100 / 255, green: 126 / 255, blue: 196 / 255))
                }

            VStack(alignment: .leading, spacing: 3) {
                Text(product.name)
                    .font(.headline.weight(.semibold))
                Text("A entregar")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("\(product.qty)")
                .font(.title3.weight(.heavy))
                .foregroundStyle(Color(red: 226 / 255, green: 27 / 255, blue: 26 / 255))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(product.accent)
                .clipShape(Capsule(style: .continuous))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.gray.opacity(0.15), lineWidth: 1)
        )
    }
}

