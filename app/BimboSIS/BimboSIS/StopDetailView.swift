import SwiftUI
import UIKit

/// Prioridad visual tipo semáforo para cantidades “a entregar”.
enum DeliverySemaphoreBadge: Hashable {
    case critical
    case warning
    case ok
}

struct Product: Identifiable {
    let id = UUID()
    let name: String
    let qty: Int
    let semaphore: DeliverySemaphoreBadge
    /// SF Symbol alineado al SKU demo (`BimboDemoProductSymbol`).
    let systemImage: String
    /// Nombre de la imagen en Assets.
    let assetName: String?
}

struct StopDetailView: View {
    let client: Client
    var onComplete: (() -> Void)? = nil

    @EnvironmentObject private var authVM: AuthViewModel
    @EnvironmentObject private var connectivity: ConnectivityViewModel

    private let products: [Product] = [
        Product(name: "Pan Blanco Grande", qty: 12, semaphore: .critical, systemImage: BimboDemoProductSymbol.systemImage(forSKU: "SKU BIM-001"), assetName: BimboDemoProductSymbol.assetName(forSKU: "SKU BIM-001")),
        Product(name: "Pan Integral", qty: 8, semaphore: .warning, systemImage: BimboDemoProductSymbol.systemImage(forSKU: "SKU BIM-002"), assetName: BimboDemoProductSymbol.assetName(forSKU: "SKU BIM-002")),
        Product(name: "Bimbollos", qty: 6, semaphore: .ok, systemImage: BimboDemoProductSymbol.systemImage(forSKU: "SKU BIM-003"), assetName: BimboDemoProductSymbol.assetName(forSKU: "SKU BIM-003"))
    ]

    @State private var showCamera = false
    @State private var capturedImage: UIImage?
    @State private var showImagePreview = false
    @Environment(\.dismiss) private var dismiss
    @State private var showRotateSheet = false
    @State private var isAnalyzing = false
    /// Total piezas confirmadas en el modal (congruente con `RotateDraftLine.rotatingQty`).
    @State private var confirmedRotationPieces = 0
    /// Último estado del modal para que al reabrir sigan cuadrando las cantidades.
    @State private var rotationDraftLines: [RotateDraftLine] = RotateProductsSheet.defaultLines

    private var rotateButtonTitle: String {
        guard confirmedRotationPieces > 0 else {
            return "Productos a Rotar"
        }
        return "Productos a Rotar (\(confirmedRotationPieces) pzs)"
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                stopHeader

                VStack(spacing: 12) {
                    sectionTitle

                    ForEach(products) { product in
                        ProductRow(product: product)
                    }

                    actionButtonsBlock

                    if showImagePreview, let img = capturedImage {
                        capturedPreview(img)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 62)
                .padding(.bottom, 28)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            }
        }
        .background(AppPalette.background.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onChange(of: connectivity.isOffline) { _, offline in
            if offline {
                showCamera = false
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            ShelfScannerView { image in
                capturedImage = image
                showImagePreview = true
                showCamera = false
            }
            .environmentObject(connectivity)
        }
        .sheet(isPresented: $showRotateSheet) {
            RotateProductsSheet(initialLines: rotationDraftLines) { result in
                rotationDraftLines = result
                confirmedRotationPieces = result.reduce(into: 0) { $0 += $1.rotatingQty }
            }
        }
        .overlay {
            if isAnalyzing {
                analysisOverlay
            }
        }
    }

    private var analysisOverlay: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView()
                    .controlSize(.large)
                    .tint(.white)
                
                Text("Analizando anaquel con IA...")
                    .font(.headline)
                    .foregroundStyle(.white)
            }
        }
    }

    /// Misma jerarquía visual que `MainRouteView.header` + tarjeta que “cae” sobre el panel blanco.
    private var stopHeader: some View {
        ZStack(alignment: .bottom) {
            AppPalette.navy
                .frame(height: 176)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .ignoresSafeArea(edges: .top)

            VStack(spacing: 22) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("PRÓXIMA PARADA · 2 DE 6")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.88))

                        Text(client.name)
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .minimumScaleFactor(0.75)
                            .lineLimit(2)
                            .foregroundStyle(.white)

                        HStack(alignment: .top, spacing: 6) {
                            Image(systemName: "location.fill")
                                .font(.subheadline.weight(.semibold))
                            Text(displayAddress)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.9))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    Spacer(minLength: 8)

                    BrandLogoToolbarCluster { authVM.signOut() }
                }

                NarrationCard()
                    .padding(.bottom, -52)
            }
            .padding(.horizontal, 20)
            .padding(.top, 52)
        }
    }

    /// Dirección con sufijo tipo maqueta cuando falta colonia.
    private var displayAddress: String {
        let addr = client.address.trimmingCharacters(in: .whitespacesAndNewlines)
        if addr.localizedCaseInsensitiveContains("col.") || addr.localizedCaseInsensitiveContains("col ") {
            return addr
        }
        return "\(addr), Col. Centro"
    }

    private var sectionTitle: some View {
        HStack {
            Text("ENTREGAR EN ESTA PARADA")
                .font(.caption.weight(.heavy))
                .foregroundStyle(.secondary)
                .tracking(0.8)
            Spacer()
        }
        .padding(.top, 4)
    }

    private var actionButtonsBlock: some View {
        VStack(spacing: 12) {
            primaryActionButton(
                title: rotateButtonTitle,
                icon: "arrow.2.circlepath",
                background: AppPalette.navy,
                foreground: .white,
                trailingIcon: nil
            ) {
                showRotateSheet = true
            }

            primaryActionButton(
                title: "Confirmar de Entregado",
                icon: "checkmark",
                background: AppPalette.secondaryButtonFill,
                foreground: AppPalette.mutedButtonForeground,
                trailingIcon: nil
            ) {
                onComplete?()
                dismiss()
            }
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.gray.opacity(0.18), lineWidth: 1)
            )

            if !connectivity.isOffline {
                primaryActionButton(
                    title: "Escanear anaquel",
                    icon: "camera.viewfinder",
                    background: AppPalette.secondaryButtonFill,
                    foreground: AppPalette.mutedButtonForeground,
                    trailingIcon: "chevron.right"
                ) {
                    showCamera = true
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.gray.opacity(0.18), lineWidth: 1)
                )
            }

            NavigationLink {
                ConfirmarOrdenView(storeName: client.name, lines: ConfirmarOrdenView.previewDemoLines)
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "doc.text.fill")
                        .font(.headline.weight(.bold))

                    Text("Ver preorden")
                        .font(.headline.weight(.bold))

                    Spacer()

                    Image(systemName: "arrow.right")
                        .font(.subheadline.weight(.black))
                }
                .foregroundStyle(AppPalette.mutedButtonForeground)
                .padding(.horizontal, 16)
                .padding(.vertical, 15)
                .frame(maxWidth: .infinity)
                .background(AppPalette.secondaryButtonFill)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.gray.opacity(0.18), lineWidth: 1)
            )
        }
        .padding(.top, 6)
    }

    private func capturedPreview(_ img: UIImage) -> some View {
        Image(uiImage: img)
            .resizable()
            .scaledToFit()
            .frame(maxHeight: 220)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.gray.opacity(0.12), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)
    }

    private func primaryActionButton(
        title: String,
        icon: String,
        background: Color,
        foreground: Color,
        trailingIcon: String?,
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
                .fill(AppPalette.brandRed)
                .frame(width: 38, height: 38)
                .overlay {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.subheadline.weight(.heavy))
                        .foregroundStyle(.white)
                }

            VStack(alignment: .leading, spacing: 2) {
                Text("Reproduciendo narración")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                Text("Audio automático - 2 repeticiones")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.82))
            }

            Spacer(minLength: 4)

            Button {
                // TODO: Repetir narración de audio.
            } label: {
                Text("Repetir")
                    .font(.caption.weight(.heavy))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(AppPalette.brandRed)
                    .clipShape(Capsule(style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(AppPalette.deepNavy)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 8)
    }
}

private struct ProductRow: View {
    let product: Product

    private var badgeBackground: Color {
        switch product.semaphore {
        case .critical:
            return AppPalette.semaphoreRedFill
        case .warning:
            return AppPalette.semaphoreYellowFill
        case .ok:
            return AppPalette.semaphoreGreenFill
        }
    }

    private var qtyForeground: Color {
        switch product.semaphore {
        case .critical:
            return AppPalette.brandRed
        case .warning:
            return AppPalette.navy
        case .ok:
            return AppPalette.semaphoreGreenText
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.gray.opacity(0.22), lineWidth: 1)
                .background(Color.white)
                .frame(width: 48, height: 48)
                .overlay {
                    if let assetName = product.assetName {
                        Image(assetName)
                            .resizable()
                            .scaledToFit()
                            .padding(4)
                    } else {
                        Image(systemName: product.systemImage)
                            .font(.title3)
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(AppPalette.stockQuantity.opacity(0.95))
                    }
                }

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .center, spacing: 6) {
                    Text(product.name)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(AppPalette.navy)

                    semaphoreDot
                }

                Text("A entregar")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(product.qty)")
                    .font(.title3.weight(.heavy))
                    .foregroundStyle(qtyForeground)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(badgeBackground)
                    .clipShape(Capsule(style: .continuous))

                Text("PZS")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.gray.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
    }

    private var semaphoreDot: some View {
        Circle()
            .fill(semaphoreDotColor)
            .frame(width: 8, height: 8)
            .accessibilityLabel(Text(accessibilitySemaphoreLabel))
    }

    private var semaphoreDotColor: Color {
        switch product.semaphore {
        case .critical: return AppPalette.brandRed
        case .warning: return AppPalette.lineYellow
        case .ok: return AppPalette.semaphoreGreenText
        }
    }

    private var accessibilitySemaphoreLabel: String {
        switch product.semaphore {
        case .critical: return "Prioridad alta"
        case .warning: return "Prioridad media"
        case .ok: return "Prioridad normal"
        }
    }
}

struct StopDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            StopDetailView(client: Client(
                name: "Tienda La Esquina",
                address: "Calle 5 de Mayo 89",
                pieces: 32,
                status: .next,
                isSuggestedRotation: true
            ))
            .environmentObject(AuthViewModel())
            .environmentObject(ConnectivityViewModel())
            .environmentObject(RouteSessionController())
        }
    }
}
