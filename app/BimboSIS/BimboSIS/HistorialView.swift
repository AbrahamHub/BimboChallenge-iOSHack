import SwiftUI

struct HistorialLineItem: Identifiable {
    let id = UUID()
    let qty: Int
    let name: String
    let lineTotal: Decimal
}

struct HistorialDelivery: Identifiable {
    let id: String
    let businessName: String
    let address: String
    let driverName: String
    let time: String
    /// Total del pedido (debe coincidir con la suma de `lines` en los datos demo).
    let amount: Decimal
    let lines: [HistorialLineItem]
}

struct HistorialView: View {
    @EnvironmentObject private var authVM: AuthViewModel

    private let deliveries: [HistorialDelivery] = [
        HistorialDelivery(
            id: "h1",
            businessName: "Abarrotes Don Chuy",
            address: "Av. Reforma 234, Col. Centro",
            driverName: "Luis Hernández",
            time: "08:42",
            amount: 1_248.50,
            lines: [
                HistorialLineItem(qty: 12, name: "Pan Blanco Grande", lineTotal: 576),
                HistorialLineItem(qty: 8, name: "Bimbollos Hot Dog", lineTotal: 308),
                HistorialLineItem(qty: 6, name: "Mantecadas Vainilla", lineTotal: 364.50)
            ]
        ),
        HistorialDelivery(
            id: "h2",
            businessName: "Tienda La Esquina",
            address: "Calle 5 de Mayo 89",
            driverName: "Luis Hernández",
            time: "09:15",
            amount: 2_100.00,
            lines: [
                HistorialLineItem(qty: 12, name: "Pan Blanco Grande", lineTotal: 624),
                HistorialLineItem(qty: 8, name: "Pan Integral", lineTotal: 448),
                HistorialLineItem(qty: 10, name: "Bimbollos", lineTotal: 440),
                HistorialLineItem(qty: 6, name: "Nito", lineTotal: 588)
            ]
        ),
        HistorialDelivery(
            id: "h3",
            businessName: "Mini Súper Lupita",
            address: "Insurgentes Sur 1102",
            driverName: "Luis Hernández",
            time: "10:03",
            amount: 1_850.00,
            lines: [
                HistorialLineItem(qty: 14, name: "Pan Blanco Grande", lineTotal: 728),
                HistorialLineItem(qty: 6, name: "Donas Glasé 4pz", lineTotal: 456),
                HistorialLineItem(qty: 12, name: "Rebanadas", lineTotal: 666)
            ]
        ),
        HistorialDelivery(
            id: "h4",
            businessName: "Abarrotes El Sol",
            address: "Blvd. Acapulco 44",
            driverName: "Luis Hernández",
            time: "11:20",
            amount: 2_010.00,
            lines: [
                HistorialLineItem(qty: 20, name: "Pan Blanco Grande", lineTotal: 1_040),
                HistorialLineItem(qty: 15, name: "Pan Integral", lineTotal: 840),
                HistorialLineItem(qty: 4, name: "Pinguino", lineTotal: 130)
            ]
        )
    ]

    private var deliveryCount: Int { deliveries.count }

    private var totalSold: Decimal {
        deliveries.reduce(into: Decimal(0)) { $0 += $1.amount }
    }

    var body: some View {
        ScrollView(showsIndicators: true) {
            VStack(spacing: 0) {
                header
                summaryBar
                deliveryList
            }
        }
        .background(AppPalette.background.ignoresSafeArea())
    }

    private var header: some View {
        ScreenHeroHeader(title: "Historial", subtitle: "Pedidos anteriores") {
            BrandLogoToolbarCluster { authVM.signOut() }
        }
    }

    private var summaryBar: some View {
        HStack {
            Text("HOY • \(deliveryCount) ENTREGAS")
                .font(.caption.weight(.heavy))
                .tracking(0.5)
                .foregroundStyle(.primary)

            Spacer()

            HStack(spacing: 4) {
                Text("Vendido")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                Text(totalSold, format: .currency(code: "MXN").locale(Locale(identifier: "es_MX")))
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(AppPalette.navy)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.white)
    }

    private var deliveryList: some View {
        LazyVStack(spacing: 12) {
            ForEach(Array(deliveries.enumerated()), id: \.element.id) { index, delivery in
                HistorialDeliveryCard(delivery: delivery, initiallyExpanded: index == 0)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 24)
    }
}

private struct HistorialDeliveryCard: View {
    let delivery: HistorialDelivery
    var initiallyExpanded: Bool = false

    @State private var isExpanded: Bool

    init(delivery: HistorialDelivery, initiallyExpanded: Bool = false) {
        self.delivery = delivery
        self.initiallyExpanded = initiallyExpanded
        _isExpanded = State(initialValue: initiallyExpanded)
    }

    private static let mxLocale = Locale(identifier: "es_MX")

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.22)) {
                    isExpanded.toggle()
                }
            } label: {
                cardHeader
            }
            .buttonStyle(.plain)

            if isExpanded {
                receiptSection
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.gray.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.03), radius: 3, x: 0, y: 2)
        .animation(.easeInOut(duration: 0.22), value: isExpanded)
    }

    private var cardHeader: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(Color(red: 233.0 / 255.0, green: 239.0 / 255.0, blue: 250.0 / 255.0))
                .frame(width: 44, height: 44)
                .overlay {
                    Image(systemName: "shippingbox.fill")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(AppPalette.navy)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(delivery.businessName)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(AppPalette.navy)
                    .lineLimit(2)
                    .minimumScaleFactor(0.9)
                    .multilineTextAlignment(.leading)

                Text(delivery.address)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Text("\(delivery.driverName) - \(delivery.time)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .trailing, spacing: 6) {
                Text(delivery.amount, format: .currency(code: "MXN").locale(Self.mxLocale))
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(AppPalette.navy)

                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.tertiary)
            }
        }
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(
            Text("\(delivery.businessName). \(isExpanded ? "Contraer recibo" : "Ver recibo de productos")")
        )
    }

    private var receiptSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("PRODUCTOS REPARTIDOS")
                .font(.caption.weight(.heavy))
                .tracking(0.6)
                .foregroundStyle(.secondary)
                .padding(.top, 10)

            VStack(spacing: 8) {
                ForEach(delivery.lines) { line in
                    HStack(alignment: .firstTextBaseline) {
                        Text("\(line.qty)× \(line.name)")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.primary)
                            .lineLimit(2)

                        Spacer(minLength: 8)

                        Text(line.lineTotal, format: .currency(code: "MXN").locale(Self.mxLocale))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppPalette.navy)
                            .layoutPriority(1)
                    }
                }
            }

            Divider()
                .padding(.vertical, 2)

            HStack {
                Text("Total")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.primary)

                Spacer()

                Text(delivery.amount, format: .currency(code: "MXN").locale(Self.mxLocale))
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(AppPalette.brandRed)
            }
        }
        .padding(.top, 4)
    }
}

struct HistorialView_Previews: PreviewProvider {
    static var previews: some View {
        HistorialView()
            .environmentObject(AuthViewModel())
            .environmentObject(ConnectivityViewModel())
    }
}
