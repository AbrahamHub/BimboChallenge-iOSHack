import SwiftUI
import UIKit

/// Línea de pedido editable antes de enviar al ERP (cantidad acotada por inventario en camión).
struct ConfirmarOrdenLine: Identifiable {
    var id: String { sku }
    let sku: String
    let name: String
    var quantity: Int
    let maxQuantity: Int
    let unitPrice: Decimal
}

/// Pantalla **Confirmar Orden** (preorden): edición con steppers; **Aceptar** lleva al **Carrito**, donde está el envío al ERP y el modal.
struct ConfirmarOrdenView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authVM: AuthViewModel

    let storeName: String
    @State private var lines: [ConfirmarOrdenLine]

    @State private var goToCart = false
    /// Después de confirmar en el modal del **Carrito** (demo: puedes enlazar API).
    var onERPSubmit: (([ConfirmarOrdenLine], Decimal) -> Void)?

    init(
        storeName: String,
        lines: [ConfirmarOrdenLine],
        onERPSubmit: (([ConfirmarOrdenLine], Decimal) -> Void)? = nil
    ) {
        self.storeName = storeName
        _lines = State(initialValue: lines.map(Self.clamped))
        self.onERPSubmit = onERPSubmit
    }

    private static func clamped(_ line: ConfirmarOrdenLine) -> ConfirmarOrdenLine {
        var copy = line
        copy.quantity = min(max(0, copy.quantity), copy.maxQuantity)
        return copy
    }

    private var productCount: Int {
        lines.filter { $0.quantity > 0 }.count
    }

    private var totalPieces: Int {
        lines.reduce(into: 0) { $0 += $1.quantity }
    }

    private var orderTotal: Decimal {
        lines.reduce(into: Decimal(0)) { partial, line in
            partial += Decimal(line.quantity) * line.unitPrice
        }
    }

    private var orderTotalFormatted: String {
        orderTotal.formatted(.currency(code: "MXN").locale(Locale(identifier: "es_MX")))
    }

    var body: some View {
        mainScroll
            .navigationBarBackButtonHidden(true)
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("Confirmar Orden")
            .toolbarBackground(AppPalette.navy, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    ToolbarSFIconButton(
                        systemName: "chevron.left",
                        fontSize: 22,
                        foreground: .white,
                        accessibilityLabelText: "Volver"
                    ) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    BrandLogoToolbarCluster { authVM.signOut() }
                }
            }
            .navigationDestination(isPresented: $goToCart) {
                CarritoOrdenView(
                    storeName: storeName,
                    lines: lines.map(Self.clamped),
                    onERPSubmit: onERPSubmit
                )
            }
    }

    private var mainScroll: some View {
        ScrollView(showsIndicators: true) {
            VStack(alignment: .leading, spacing: 0) {
                storeHeaderBlock

                LazyVStack(spacing: 12) {
                    ForEach($lines) { $line in
                        BimboStepperProductCard(
                            title: line.name,
                            detail: "\(line.quantity) pzs",
                            quantity: $line.quantity,
                            maxQuantity: line.maxQuantity,
                            useIconPlaceholder: false,
                            systemImage: BimboDemoProductSymbol.systemImage(forSKU: line.sku),
                            assetName: BimboDemoProductSymbol.assetName(forSKU: line.sku)
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)

                summaryBox
                    .padding(.horizontal, 16)
                    .padding(.top, 18)

                Color.clear.frame(height: 100)
            }
        }
        .background(AppPalette.background.ignoresSafeArea())
        .safeAreaInset(edge: .bottom, spacing: 0) {
            sendBar
        }
    }

    private var storeHeaderBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(storeName)
                .font(.title2.weight(.bold))
                .foregroundStyle(.primary)

            Text("\(productCount) productos · \(totalPieces) piezas")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.2), value: productCount)
                .animation(.easeInOut(duration: 0.2), value: totalPieces)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 4)
        .background(Color.white)
    }

    private var summaryBox: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Productos")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(productCount)")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.primary)
            }
            HStack {
                Text("Total piezas")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(totalPieces)")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.primary)
            }
        }
        .padding(16)
        .background(AppPalette.secondaryButtonFill)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var sendBar: some View {
        Button {
            guard totalPieces > 0 else { return }
            goToCart = true
        } label: {
            Text("Aceptar")
                .font(.headline.weight(.bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .foregroundStyle(.white)
                .background(AppPalette.brandRed)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(totalPieces == 0 || productCount == 0)
        .opacity(totalPieces == 0 ? 0.45 : 1)
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(AppPalette.background)
    }
}

// MARK: - Carrito (resumen + modal ERP → menú principal)

struct CarritoOrdenView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authVM: AuthViewModel
    @EnvironmentObject private var routeSession: RouteSessionController

    let storeName: String
    @State private var lines: [ConfirmarOrdenLine]

    @State private var showERPConfirmModal = false
    var onERPSubmit: (([ConfirmarOrdenLine], Decimal) -> Void)?

    init(
        storeName: String,
        lines: [ConfirmarOrdenLine],
        onERPSubmit: (([ConfirmarOrdenLine], Decimal) -> Void)? = nil
    ) {
        self.storeName = storeName
        _lines = State(initialValue: lines.map { Self.clamp($0) })
        self.onERPSubmit = onERPSubmit
    }

    private static func clamp(_ line: ConfirmarOrdenLine) -> ConfirmarOrdenLine {
        var copy = line
        copy.quantity = min(max(0, copy.quantity), copy.maxQuantity)
        return copy
    }

    private var productCount: Int {
        lines.filter { $0.quantity > 0 }.count
    }

    private var totalPieces: Int {
        lines.reduce(into: 0) { $0 += $1.quantity }
    }

    private var orderTotal: Decimal {
        lines.reduce(into: Decimal(0)) { partial, line in
            partial += Decimal(line.quantity) * line.unitPrice
        }
    }

    private var orderTotalFormatted: String {
        orderTotal.formatted(.currency(code: "MXN").locale(Locale(identifier: "es_MX")))
    }

    var body: some View {
        ZStack {
            carritoScroll

            if showERPConfirmModal {
                ConfirmarEnvioERPModal(
                    storeName: storeName,
                    productCount: productCount,
                    totalPieces: totalPieces,
                    totalFormatted: orderTotalFormatted,
                    onCancel: { showERPConfirmModal = false },
                    onConfirm: {
                        showERPConfirmModal = false
                        let snapshot = lines.map(Self.clamp)
                        onERPSubmit?(snapshot, orderTotal)
                        routeSession.completePurchaseAndReturnToMainMenu()
                    }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.96)))
                .zIndex(1)
            }
        }
        .animation(.spring(response: 0.32, dampingFraction: 0.86), value: showERPConfirmModal)
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Carrito")
        .toolbarBackground(AppPalette.navy, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                ToolbarSFIconButton(
                    systemName: "chevron.left",
                    fontSize: 22,
                    foreground: .white,
                    accessibilityLabelText: "Volver a preorden"
                ) {
                    dismiss()
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                BrandLogoToolbarCluster { authVM.signOut() }
            }
        }
    }

    private var carritoScroll: some View {
        ScrollView(showsIndicators: true) {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(storeName)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.primary)
                    Text("\(productCount) productos · \(totalPieces) piezas")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(orderTotalFormatted)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(AppPalette.navy)
                        .padding(.top, 4)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color.white)

                LazyVStack(spacing: 10) {
                    ForEach(lines.filter { $0.quantity > 0 }) { line in
                        carritoLineRow(line)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)

                Color.clear.frame(height: 120)
            }
        }
        .background(AppPalette.background.ignoresSafeArea())
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Button {
                guard totalPieces > 0 else { return }
                showERPConfirmModal = true
            } label: {
                Text("Enviar orden al ERP")
                    .font(.headline.weight(.bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .foregroundStyle(.white)
                    .background(AppPalette.brandRed)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(totalPieces == 0)
            .opacity(totalPieces == 0 ? 0.45 : 1)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(AppPalette.background)
        }
    }

    private func carritoLineRow(_ line: ConfirmarOrdenLine) -> some View {
        HStack(spacing: 12) {
            productThumb(sku: line.sku)
            VStack(alignment: .leading, spacing: 4) {
                Text(line.name)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(AppPalette.navy)
                    .lineLimit(2)
                Text("\(line.quantity) pzs · \(lineSubtotal(line).formatted(.currency(code: "MXN").locale(Locale(identifier: "es_MX"))))")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
        }
        .padding(12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.gray.opacity(0.14), lineWidth: 1)
        )
    }

    private func lineSubtotal(_ line: ConfirmarOrdenLine) -> Decimal {
        Decimal(line.quantity) * line.unitPrice
    }

    @ViewBuilder
    private func productThumb(sku: String) -> some View {
        let name = BimboDemoProductSymbol.assetName(forSKU: sku)
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            .background(Color.white)
            .frame(width: 52, height: 52)
            .overlay {
                if let name, let img = UIImage(named: name) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFit()
                        .padding(6)
                } else {
                    Image(systemName: BimboDemoProductSymbol.systemImage(forSKU: sku))
                        .font(.title3)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(AppPalette.stockQuantity.opacity(0.95))
                }
            }
    }
}

// MARK: - Modal confirmación ERP

struct ConfirmarEnvioERPModal: View {
    let storeName: String
    let productCount: Int
    let totalPieces: Int
    let totalFormatted: String
    let onCancel: () -> Void
    let onConfirm: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.48)
                .ignoresSafeArea()
                .onTapGesture(perform: onCancel)

            VStack(spacing: 0) {
                VStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 54, height: 54)
                        Image(systemName: "checkmark")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.black)
                    }

                    Text("Confirmar y Finalizar Visita")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 22)
                .padding(.horizontal, 16)
                .background(AppPalette.navy)

                VStack(spacing: 20) {
                    confirmationMessage
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 12) {
                        Button(action: onCancel) {
                            Text("Cancelar")
                                .font(.headline.weight(.bold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .foregroundStyle(.primary)
                                .background(AppPalette.secondaryButtonFill)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .buttonStyle(.plain)

                        Button(action: onConfirm) {
                            Text("Confirmar")
                                .font(.headline.weight(.bold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .foregroundStyle(.white)
                                .background(AppPalette.brandRed)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(20)
                .background(Color.white)
            }
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(color: .black.opacity(0.22), radius: 24, x: 0, y: 12)
            .padding(.horizontal, 28)
        }
    }

    private var confirmationMessage: some View {
        Text(attributedConfirmation)
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.primary)
    }

    private var attributedConfirmation: AttributedString {
        let boldSnippet = "\(storeName) (\(productCount) productos · \(totalPieces) piezas · \(totalFormatted))"
        var base = AttributedString("¿Confirmas el envío de la orden de ")
        var bold = AttributedString(boldSnippet)
        bold.font = .subheadline.bold()
        base.append(bold)
        base.append(AttributedString(" al ERP?"))
        return base
    }
}

extension ConfirmarOrdenView {
    /// Demo alineado al mock: **Tienda La Esquina**, 5 productos, 40 piezas, total **$1,248.00 MXN**.
    static var previewDemoLines: [ConfirmarOrdenLine] {
        [
            ConfirmarOrdenLine(sku: "SKU BIM-001", name: "Pan Blanco Grande", quantity: 12, maxQuantity: 24, unitPrice: 26),
            ConfirmarOrdenLine(sku: "SKU BIM-002", name: "Pan Integral", quantity: 8, maxQuantity: 18, unitPrice: 28),
            ConfirmarOrdenLine(sku: "SKU BIM-003", name: "Bimbollos", quantity: 6, maxQuantity: 16, unitPrice: 22),
            ConfirmarOrdenLine(sku: "SKU BIM-005", name: "Donas Glasé 4pz", quantity: 8, maxQuantity: 9, unitPrice: 38),
            ConfirmarOrdenLine(sku: "SKU BIM-004", name: "Nito", quantity: 6, maxQuantity: 12, unitPrice: 46)
        ]
    }
}

struct ConfirmarOrdenView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ConfirmarOrdenView(storeName: "Tienda La Esquina", lines: ConfirmarOrdenView.previewDemoLines)
        }
        .environmentObject(AuthViewModel())
        .environmentObject(ConnectivityViewModel())
        .environmentObject(RouteSessionController())
    }
}

struct CarritoOrdenView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            CarritoOrdenView(storeName: "Tienda La Esquina", lines: ConfirmarOrdenView.previewDemoLines)
        }
        .environmentObject(AuthViewModel())
        .environmentObject(ConnectivityViewModel())
        .environmentObject(RouteSessionController())
    }
}
