import SwiftUI

private enum MedicationTileGridLayout {
    static let columnCount = 3
}

struct MedicationTileGrid: View {
    let schema: SchemaConfig
    @Bindable var medicationPreferences: MedicationPreferences

    @State private var showAddRelief = false

    private var reliefOptions: [FieldValueOption] {
        ReliefOptions.all(from: schema, customReliefs: medicationPreferences.customReliefs)
    }

    var body: some View {
        CareTileGrid(columnCount: MedicationTileGridLayout.columnCount) {
            ForEach(reliefOptions) { option in
                CareSelectionTile(
                    title: option.label,
                    isSelected: medicationPreferences.isSaved(option.key),
                    shape: .square
                ) {
                    medicationPreferences.setSaved(
                        option.key,
                        isSaved: !medicationPreferences.isSaved(option.key)
                    )
                }
            }

            Button {
                showAddRelief = true
            } label: {
                CareAddReliefTile(shape: .square)
            }
            .buttonStyle(.plain)
        }
        .sheet(isPresented: $showAddRelief) {
            NavigationStack {
                AddCustomReliefView(
                    schema: schema,
                    medicationPreferences: medicationPreferences
                )
            }
            .presentationDetents([.medium])
        }
    }
}
