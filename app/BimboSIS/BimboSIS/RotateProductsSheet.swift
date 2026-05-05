import SwiftUI

/// Línea editable dentro del modal “Productos a Rotar”.
/// `onTruckPieces` = inventario hardcodeado coherente con Stock; `rotatingQty` es lo que el usuario suma/resta.
struct RotateDraftLine: Identifiable {
    var id: String { sku }
    let sku: String
    let name: String
    /// Piezas disponibles en el camión para rotar (tope del botón +).
    let onTruckPieces: Int
    /// Piezas marcadas para esta rotación (0 … onTruckPieces).
    var rotatingQty: Int
}

struct RotateProductsSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var searchText = ""
    @State private var lines: [RotateDraftLine]

    var onConfirm: (([RotateDraftLine]) -> Void)?

    init(
        initialLines: [RotateDraftLine],
        onConfirm: (([RotateDraftLine]) -> Void)? = nil
    ) {
        _lines = State(initialValue: initialLines.map(Self.clampedLine))
        self.onConfirm = onConfirm
    }

    private static func clampedLine(_ line: RotateDraftLine) -> RotateDraftLine {
        var copy = line
        copy.rotatingQty = min(max(0, copy.rotatingQty), copy.onTruckPieces)
        return copy
    }

    private var filteredIndices: [Int] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return Array(lines.indices) }
        return lines.indices.filter {
            lines[$0].name.lowercased().contains(q) || lines[$0].sku.lowercased().contains(q)
        }
    }

    /// SKUs con al menos 1 pieza marcada para rotar.
    private var selectedSKUCount: Int {
        lines.filter { $0.rotatingQty > 0 }.count
    }

    /// Suma de piezas marcadas (reactiva a +/-).
    private var rotatingPieces: Int {
        lines.reduce(into: 0) { $0 += $1.rotatingQty }
    }

    /// Piezas aún disponibles para seguir sumando en la lista visible (solo referencia informativa).
    private var remainingCapacityOnFilteredList: Int {
        filteredIndices.reduce(into: 0) { partial, idx in
            partial += max(0, lines[idx].onTruckPieces - lines[idx].rotatingQty)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                sheetHeader

                ScrollView(showsIndicators: true) {
                    VStack(spacing: 14) {
                        searchField
                        summaryRow

                        LazyVStack(spacing: 12) {
                            ForEach(filteredIndices, id: \.self) { idx in
                                RotateProductRow(
                                    name: lines[idx].name,
                                    sku: lines[idx].sku,
                                    systemImage: BimboDemoProductSymbol.systemImage(forSKU: lines[idx].sku),
                                    onTruckPieces: lines[idx].onTruckPieces,
                                    rotatingQty: Binding(
                                        get: { lines[idx].rotatingQty },
                                        set: { newVal in
                                            var row = lines[idx]
                                            row.rotatingQty = min(max(0, newVal), row.onTruckPieces)
                                            lines[idx] = row
                                        }
                                    )
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 100)
                }

                footerBar
            }
            .background(AppPalette.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    ToolbarSFIconButton(
                        systemName: "xmark.circle.fill",
                        fontSize: 28,
                        foreground: AppPalette.navy,
                        accessibilityLabelText: "Cerrar"
                    ) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Poner todo en cero", systemImage: "arrow.counterclockwise.circle") {
                            resetAllToZero()
                        }
                        Button("Usar sugerencia demo (12 pzs total)", systemImage: "wand.and.stars") {
                            applyDemoSuggestion()
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle.fill")
                            .font(.system(size: 28, weight: .semibold))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(AppPalette.navy)
                            .frame(minWidth: 44, minHeight: 44)
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel(Text("Más opciones"))
                }
            }
        }
        .presentationDragIndicator(.visible)
    }

    private func resetAllToZero() {
        for i in lines.indices {
            lines[i].rotatingQty = 0
        }
    }

    /// Reparte una rotación demo coherente sin pasar del stock en camión.
    private func applyDemoSuggestion() {
        resetAllToZero()
        let demo: [(String, Int)] = [
            ("SKU BIM-001", 6),
            ("SKU BIM-002", 4),
            ("SKU BIM-003", 2)
        ]
        for (sku, q) in demo {
            guard let i = lines.firstIndex(where: { $0.sku == sku }) else { continue }
            lines[i].rotatingQty = min(q, lines[i].onTruckPieces)
        }
    }

    private var sheetHeader: some View {
        ZStack {
            AppPalette.navy
                .frame(height: 152)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

            VStack(spacing: 10) {
                Circle()
                    .fill(Color.white)
                    .frame(width: 44, height: 44)
                    .overlay {
                        Image(systemName: "arrow.2.circlepath")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(AppPalette.navy)
                    }

                Text("Productos a Rotar")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)

                Text("\(selectedSKUCount) SKUs - \(rotatingPieces) pzs")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.88))
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.2), value: selectedSKUCount)
                    .animation(.easeInOut(duration: 0.2), value: rotatingPieces)
            }
            .padding(.top, 28)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private var searchField: some View {
        BimboSearchField(text: $searchText)
    }

    private var summaryRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("\(lines.count) PRODUCTOS")
                    .font(.caption.weight(.heavy))
                    .tracking(0.6)
                    .foregroundStyle(.primary)

                Spacer()

                HStack(spacing: 4) {
                    Text("Rotando")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text("\(rotatingPieces)")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(AppPalette.navy)
                        .contentTransition(.numericText())
                        .animation(.easeInOut(duration: 0.2), value: rotatingPieces)
                    Text("pzs")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 4) {
                Text("Cupos libres en lista:")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
                Text("\(remainingCapacityOnFilteredList) pzs")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(AppPalette.stockQuantity)
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.2), value: remainingCapacityOnFilteredList)
            }
        }
    }

    private var footerBar: some View {
        HStack(spacing: 12) {
            Button {
                dismiss()
            } label: {
                Text("Cancelar")
                    .font(.headline.weight(.bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .foregroundStyle(AppPalette.navy)
                    .background(AppPalette.secondaryButtonFill)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)

            Button {
                let snapshot = lines.map(Self.clampedLine)
                lines = snapshot
                onConfirm?(snapshot)
                dismiss()
            } label: {
                Text("Confirmar rotación")
                    .font(.headline.weight(.bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .foregroundStyle(.white)
                    .background(AppPalette.rotatedProductsBlue)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(rotatingPieces == 0)
            .opacity(rotatingPieces == 0 ? 0.45 : 1)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.gray.opacity(0.15))
                .frame(height: 1)
        }
    }
}

private struct RotateProductRow: View {
    let name: String
    let sku: String
    let systemImage: String
    let onTruckPieces: Int
    @Binding var rotatingQty: Int

    private var canIncrement: Bool {
        rotatingQty < onTruckPieces
    }

    private var canDecrement: Bool {
        rotatingQty > 0
    }

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.gray.opacity(0.22), lineWidth: 1)
                .background(Color.white)
                .frame(width: 52, height: 52)
                .overlay {
                    Image(systemName: systemImage)
                        .font(.title3)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(AppPalette.stockQuantity.opacity(0.95))
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(AppPalette.navy)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)

                Text(sku)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("En camión: \(onTruckPieces) pzs (máx. a rotar)")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            HStack(spacing: 10) {
                Button {
                    guard canDecrement else { return }
                    rotatingQty -= 1
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

                Text("\(rotatingQty)")
                    .font(.title3.weight(.bold))
                    .monospacedDigit()
                    .frame(minWidth: 26)
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.15), value: rotatingQty)

                Button {
                    guard canIncrement else { return }
                    rotatingQty += 1
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
        .accessibilityLabel(Text("\(name), \(rotatingQty) de \(onTruckPieces) piezas para rotar"))
    }
}

extension RotateProductsSheet {
    /// Inventario en camión alineado al mock de `StockView` (mismos SKU y cantidades base).
    static var defaultLines: [RotateDraftLine] {
        [
            RotateDraftLine(sku: "SKU BIM-001", name: "Pan Blanco Grande", onTruckPieces: 24, rotatingQty: 0),
            RotateDraftLine(sku: "SKU BIM-002", name: "Pan Integral", onTruckPieces: 18, rotatingQty: 0),
            RotateDraftLine(sku: "SKU BIM-003", name: "Bimbollos Hot Dog", onTruckPieces: 16, rotatingQty: 0),
            RotateDraftLine(sku: "SKU BIM-004", name: "Medias Noches", onTruckPieces: 12, rotatingQty: 0),
            RotateDraftLine(sku: "SKU BIM-005", name: "Donas Glasé 4pz", onTruckPieces: 9, rotatingQty: 0),
            RotateDraftLine(sku: "SKU BIM-006", name: "Mantecadas", onTruckPieces: 30, rotatingQty: 0),
            RotateDraftLine(sku: "SKU BIM-007", name: "Rebanadas", onTruckPieces: 28, rotatingQty: 0),
            RotateDraftLine(sku: "SKU BIM-008", name: "Pingüino", onTruckPieces: 35, rotatingQty: 0)
        ]
    }
}

struct RotateProductsSheet_Previews: PreviewProvider {
    static var previews: some View {
        RotateProductsSheet(initialLines: RotateProductsSheet.defaultLines)
    }
}
