import SwiftUI

private enum MedicationTileGridLayout {
    static let columnCount = 3

    static func tileSize(forContentWidth contentWidth: CGFloat) -> CGFloat {
        let gutter = CareTileLayout.gutter
        let preferredSize = CareTileLayout.size
        let requiredWidth = CGFloat(columnCount) * preferredSize + CGFloat(columnCount - 1) * gutter
        guard requiredWidth > contentWidth, contentWidth > 0 else {
            return preferredSize
        }
        return floor((contentWidth - CGFloat(columnCount - 1) * gutter) / CGFloat(columnCount))
    }
}

private struct MedicationGridWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct MedicationTileGrid: View {
    let schema: SchemaConfig
    @Bindable var medicationPreferences: MedicationPreferences
    var onAlarmChange: () -> Void = {}

    @State private var gridWidth: CGFloat = 0
    @State private var showAddRelief = false
    @State private var reliefAlarmSheetItem: ReliefAlarmSheetItem?

    private var reliefOptions: [FieldValueOption] {
        ReliefOptions.gridOptions(
            from: schema,
            customReliefs: medicationPreferences.customReliefs,
            hiddenReliefKeys: medicationPreferences.hiddenReliefKeys
        )
    }

    private var columnCount: Int {
        MedicationTileGridLayout.columnCount
    }

    /// Schema + custom options, then the add tile.
    private var gridItemCount: Int {
        reliefOptions.count + 1
    }

    private var rowIndices: Range<Int> {
        let rowCount = (gridItemCount + columnCount - 1) / columnCount
        return 0..<max(rowCount, 0)
    }

    private var tileSize: CGFloat {
        MedicationTileGridLayout.tileSize(forContentWidth: gridWidth)
    }

    var body: some View {
        Grid(
            horizontalSpacing: CareTileLayout.gutter,
            verticalSpacing: CareTileLayout.gutter
        ) {
            ForEach(rowIndices, id: \.self) { rowIndex in
                GridRow {
                    ForEach(0..<columnCount, id: \.self) { columnIndex in
                        cell(at: rowIndex * columnCount + columnIndex, in: rowIndex)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .background {
            GeometryReader { geometry in
                Color.clear.preference(
                    key: MedicationGridWidthKey.self,
                    value: geometry.size.width
                )
            }
        }
        .onPreferenceChange(MedicationGridWidthKey.self) { gridWidth = $0 }
        .sheet(isPresented: $showAddRelief) {
            NavigationStack {
                AddCustomReliefView(
                    schema: schema,
                    medicationPreferences: medicationPreferences
                )
            }
            .presentationDetents([.medium])
        }
        .sheet(item: $reliefAlarmSheetItem) { item in
            ReliefAlarmSheet(
                item: item,
                medicationPreferences: medicationPreferences,
                onSave: onAlarmChange,
                onRemoveMedicine: onAlarmChange
            )
        }
    }

    @ViewBuilder
    private func cell(at index: Int, in rowIndex: Int) -> some View {
        if index < reliefOptions.count {
            let option = reliefOptions[index]
            CareSelectionTile(
                title: option.label,
                subtitle: medicationPreferences.formattedAlarmTime(for: option.key),
                detail: medicationPreferences.formattedAlarmRepeat(for: option.key),
                footnote: medicationPreferences.formattedAlarmDuration(for: option.key),
                isSelected: medicationPreferences.isSaved(option.key),
                tileWidth: tileSize,
                tileHeight: tileSize,
                onLongPress: {
                    reliefAlarmSheetItem = ReliefAlarmSheetItem(
                        key: option.key,
                        label: option.label
                    )
                }
            ) {
                medicationPreferences.setSaved(
                    option.key,
                    isSaved: !medicationPreferences.isSaved(option.key)
                )
            }
        } else if index == reliefOptions.count {
            Button {
                showAddRelief = true
            } label: {
                CareAddReliefTile(tileWidth: tileSize, tileHeight: tileSize)
            }
            .buttonStyle(.plain)
        } else if needsPlaceholder(in: rowIndex, at: index) {
            Color.clear
                .frame(width: tileSize, height: tileSize)
                .accessibilityHidden(true)
        }
    }

    private func needsPlaceholder(in rowIndex: Int, at index: Int) -> Bool {
        let remainder = gridItemCount % columnCount
        guard remainder != 0 else { return false }
        let lastRowIndex = gridItemCount / columnCount
        return rowIndex == lastRowIndex && index >= gridItemCount
    }
}
