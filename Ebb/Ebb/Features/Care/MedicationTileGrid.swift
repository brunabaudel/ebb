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

    @State private var gridWidth: CGFloat = 0

    private var reliefOptions: [FieldValueOption] {
        schema.field(forKey: "relief_taken")?.values ?? []
    }

    private var columnCount: Int {
        MedicationTileGridLayout.columnCount
    }

    private var rowIndices: Range<Int> {
        let rowCount = (reliefOptions.count + columnCount - 1) / columnCount
        return 0..<max(rowCount, 0)
    }

    private var tileSize: CGFloat {
        MedicationTileGridLayout.tileSize(forContentWidth: gridWidth)
    }

    var body: some View {
        CareTileGrid {
            ForEach(rowIndices, id: \.self) { rowIndex in
                GridRow {
                    ForEach(0..<columnCount, id: \.self) { columnIndex in
                        cell(at: rowIndex * columnCount + columnIndex, in: rowIndex)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .background {
            GeometryReader { geometry in
                Color.clear.preference(
                    key: MedicationGridWidthKey.self,
                    value: geometry.size.width
                )
            }
        }
        .onPreferenceChange(MedicationGridWidthKey.self) { gridWidth = $0 }
    }

    @ViewBuilder
    private func cell(at index: Int, in rowIndex: Int) -> some View {
        if index < reliefOptions.count {
            let option = reliefOptions[index]
            CareSelectionTile(
                title: option.label,
                isSelected: medicationPreferences.isSaved(option.key),
                tileWidth: tileSize,
                tileHeight: tileSize
            ) {
                medicationPreferences.setSaved(
                    option.key,
                    isSaved: !medicationPreferences.isSaved(option.key)
                )
            }
        } else if needsPlaceholder(in: rowIndex, at: index) {
            Color.clear
                .frame(width: tileSize, height: tileSize)
                .accessibilityHidden(true)
        }
    }

    private func needsPlaceholder(in rowIndex: Int, at index: Int) -> Bool {
        let remainder = reliefOptions.count % columnCount
        guard remainder != 0 else { return false }
        let lastRowIndex = reliefOptions.count / columnCount
        return rowIndex == lastRowIndex && index >= reliefOptions.count
    }
}
