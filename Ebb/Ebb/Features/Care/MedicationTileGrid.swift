import SwiftUI

private enum MedicationTileGridLayout {
    static let columnCount = 3
}

struct MedicationTileGrid: View {
    let schema: SchemaConfig
    @Bindable var medicationPreferences: MedicationPreferences
    var onAlarmChange: () -> Void = {}

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var showAddRelief = false
    @State private var reliefAlarmSheetItem: ReliefAlarmSheetItem?

    private var reliefOptions: [FieldValueOption] {
        ReliefOptions.gridOptions(
            from: schema,
            customReliefs: medicationPreferences.customReliefs,
            hiddenReliefKeys: medicationPreferences.hiddenReliefKeys
        )
    }

    var body: some View {
        CareTileGrid(columnCount: MedicationTileGridLayout.columnCount) {
            ForEach(reliefOptions) { option in
                reliefTile(for: option)
            }

            Button {
                showAddRelief = true
            } label: {
                CareAddReliefTile(shape: .flexibleSquare)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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

    private func reliefTile(for option: FieldValueOption) -> some View {
        CareSelectionTile(
            title: option.label,
            subtitle: medicationPreferences.formattedAlarmTime(for: option.key),
            detail: medicationPreferences.formattedAlarmRepeat(for: option.key),
            footnote: medicationPreferences.formattedAlarmDuration(for: option.key),
            isSelected: medicationPreferences.isSaved(option.key),
            shape: .flexibleSquare,
            onLongPress: {
                openReliefAlarmSheet(for: option)
            }
        ) {
            if hasAlarm(for: option.key) {
                let toggle = {
                    medicationPreferences.setSaved(
                        option.key,
                        isSaved: !medicationPreferences.isSaved(option.key)
                    )
                    onAlarmChange()
                }
                if reduceMotion {
                    toggle()
                } else {
                    withAnimation(.smooth(duration: 0.28)) {
                        toggle()
                    }
                }
            } else {
                openReliefAlarmSheet(for: option)
            }
        }
    }

    private func hasAlarm(for key: String) -> Bool {
        medicationPreferences.formattedAlarmTime(for: key) != nil
    }

    private func openReliefAlarmSheet(for option: FieldValueOption) {
        reliefAlarmSheetItem = ReliefAlarmSheetItem(
            key: option.key,
            label: option.label
        )
    }
}
