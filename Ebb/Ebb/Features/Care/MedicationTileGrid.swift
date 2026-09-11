import SwiftUI

struct MedicationTileGrid: View {
    let schema: SchemaConfig
    @Bindable var medicationPreferences: MedicationPreferences

    private var reliefOptions: [FieldValueOption] {
        schema.field(forKey: "relief_taken")?.values ?? []
    }

    var body: some View {
        CareTileGrid {
            ForEach(rowIndices, id: \.self) { rowIndex in
                GridRow {
                    tile(at: rowIndex * CareTileLayout.columnCount)
                    if hasSecondColumn(in: rowIndex) {
                        tile(at: rowIndex * CareTileLayout.columnCount + 1)
                    }
                }
            }
        }
    }

    private var rowIndices: Range<Int> {
        let rowCount = (reliefOptions.count + CareTileLayout.columnCount - 1) / CareTileLayout.columnCount
        return 0..<max(rowCount, 0)
    }

    private func hasSecondColumn(in rowIndex: Int) -> Bool {
        rowIndex * CareTileLayout.columnCount + 1 < reliefOptions.count
    }

    @ViewBuilder
    private func tile(at index: Int) -> some View {
        if index < reliefOptions.count {
            let option = reliefOptions[index]
            CareSelectionTile(
                title: option.label,
                isSelected: medicationPreferences.isSaved(option.key)
            ) {
                medicationPreferences.setSaved(
                    option.key,
                    isSaved: !medicationPreferences.isSaved(option.key)
                )
            }
        }
    }
}
