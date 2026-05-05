import SwiftUI

struct HistorialDelivery: Identifiable {
    let id: String
    let businessName: String
    let address: String
    let driverName: String
    let time: String
    let amount: Decimal
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
            amount: 1_248.50
        ),
        HistorialDelivery(
            id: "h2",
            businessName: "Tienda La Esquina",
            address: "Calle 5 de Mayo 89",
            driverName: "Luis Hernández",
            time: "09:15",
            amount: 2_100.00
        ),
        HistorialDelivery(
            id: "h3",
            businessName: "Mini Súper Lupita",
            address: "Insurgentes Sur 1102",
            driverName: "Luis Hernández",
            time: "10:03",
            amount: 1_850.00
        ),
        HistorialDelivery(
            id: "h4",
            businessName: "Abarrotes El Sol",
            address: "Blvd. Acapulco 44",
            driverName: "Luis Hernández",
            time: "11:20",
            amount: 2_010.00
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
                Text(totalSold, format: .currency(code: "MXN"))
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
            ForEach(deliveries) { delivery in
                HistorialDeliveryCard(delivery: delivery)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 24)
    }
}

private struct HistorialDeliveryCard: View {
    let delivery: HistorialDelivery

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(Color(red: 233.0 / 255.0, green: 239.0 / 255.0, blue: 250.0 / 255.0))
                .frame(width: 44, height: 44)
                .overlay {
                    Image(systemName: "shippingbox")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(AppPalette.navy)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(delivery.businessName)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(AppPalette.navy)
                    .lineLimit(2)
                    .minimumScaleFactor(0.9)

                Text(delivery.address)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                Text("\(delivery.driverName) • \(delivery.time)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .trailing, spacing: 4) {
                Text(delivery.amount, format: .currency(code: "MXN"))
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(AppPalette.navy)

                Image(systemName: "chevron.down")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.tertiary)
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
    }
}

struct HistorialView_Previews: PreviewProvider {
    static var previews: some View {
        HistorialView()
            .environmentObject(AuthViewModel())
            .environmentObject(ConnectivityViewModel())
    }
}
