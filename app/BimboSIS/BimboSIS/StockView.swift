import SwiftUI

struct StockLineItem: Identifiable {
    var id: String { sku }
    let name: String
    let sku: String
    let quantity: Int
    let isLowStock: Bool
}

struct StockView: View {
    @EnvironmentObject private var authVM: AuthViewModel
    @State private var searchText = ""

    private let items: [StockLineItem] = [
        StockLineItem(name: "Pan Blanco Grande", sku: "SKU BIM-001", quantity: 24, isLowStock: false),
        StockLineItem(name: "Pan Integral", sku: "SKU BIM-002", quantity: 18, isLowStock: false),
        StockLineItem(name: "Bimbollos", sku: "SKU BIM-003", quantity: 16, isLowStock: false),
        StockLineItem(name: "Nito", sku: "SKU BIM-004", quantity: 12, isLowStock: false),
        StockLineItem(name: "Donas Glasé 4pz", sku: "SKU BIM-005", quantity: 9, isLowStock: true),
        StockLineItem(name: "Mantecadas", sku: "SKU BIM-006", quantity: 30, isLowStock: false),
        StockLineItem(name: "Rebanadas", sku: "SKU BIM-007", quantity: 28, isLowStock: false),
        StockLineItem(name: "Pingüino", sku: "SKU BIM-008", quantity: 35, isLowStock: false)
    ]

    private var filteredItems: [StockLineItem] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return items }
        return items.filter {
            $0.name.lowercased().contains(q) || $0.sku.lowercased().contains(q)
        }
    }

    private var totalPieces: Int {
        filteredItems.reduce(into: 0) { $0 += $1.quantity }
    }

    var body: some View {
        ScrollView(showsIndicators: true) {
            VStack(spacing: 0) {
                header
                searchAndSummary
                listSection
            }
        }
        .background(AppPalette.background.ignoresSafeArea())
    }

    private var header: some View {
        ScreenHeroHeader(title: "Stock", subtitle: "Inventario disponible en camión") {
            BrandLogoButton { authVM.signOut() }
        }
    }

    private var searchAndSummary: some View {
        VStack(spacing: 14) {
            BimboSearchField(text: $searchText)

            HStack {
                Text("\(filteredItems.count) PRODUCTOS")
                    .font(.caption.weight(.heavy))
                    .tracking(0.6)
                    .foregroundStyle(.secondary)

                Spacer()

                HStack(spacing: 4) {
                    Text("Total")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text("\(totalPieces)")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.primary)
                    Text("pzs")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 6)
    }

    private var listSection: some View {
        LazyVStack(spacing: 12) {
            ForEach(filteredItems) { item in
                StockProductRow(item: item)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 4)
        .padding(.bottom, 24)
    }
}

private struct StockProductRow: View {
    let item: StockLineItem

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.gray.opacity(0.22), lineWidth: 1)
                .background(Color.white)
                .frame(width: 52, height: 52)
                .overlay {
                    Image(systemName: "photo")
                        .font(.title3)
                        .foregroundStyle(.tertiary)
                }

            VStack(alignment: .leading, spacing: 3) {
                Text(item.name)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(AppPalette.navy)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)

                Text(item.sku)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(item.quantity)")
                    .font(.title2.weight(.heavy))
                    .foregroundStyle(item.isLowStock ? AppPalette.brandRed : AppPalette.stockQuantity)

                Text("PZS")
                    .font(.caption2.weight(.heavy))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.gray.opacity(0.14), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.03), radius: 3, x: 0, y: 2)
    }
}

struct StockView_Previews: PreviewProvider {
    static var previews: some View {
        StockView()
            .environmentObject(AuthViewModel())
    }
}
