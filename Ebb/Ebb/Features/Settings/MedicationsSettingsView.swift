import SwiftData
import SwiftUI

struct MedicationsSettingsView: View {
    let schema: SchemaConfig
    @Bindable var medicationPreferences: MedicationPreferences

    @Environment(\.theme) private var theme
    @Environment(ReminderPreferences.self) private var reminderPreferences
    @Environment(CycleService.self) private var cycleService
    @Query(sort: \SymptomEntry.timestamp, order: .reverse) private var entries: [SymptomEntry]

    var body: some View {
        List {
            Section {
                Text("These appear pre-selected on the relief screen, so logging what you took is one tap.")
                    .font(.footnote)
                    .foregroundStyle(theme.muted)
                    .themeListRow()
            }

            Section {
                MedicationTileGrid(
                    schema: schema,
                    medicationPreferences: medicationPreferences,
                    onAlarmChange: rescheduleReliefAlarms
                )
                .padding(.vertical, 4)
            }
            .listRowBackground(theme.base)
            .listRowSeparator(.hidden)
            .listSectionSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
        }
        .themeSettingsList()
        .navigationTitle("My medications")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func rescheduleReliefAlarms() {
        ReminderScheduling.rescheduleReliefAlarms(
            schema: schema,
            medicationPreferences: medicationPreferences,
            preferences: reminderPreferences,
            entries: entries
        )
    }
}

#Preview {
    NavigationStack {
        MedicationsSettingsView(
            schema: try! SchemaConfig.load(),
            medicationPreferences: MedicationPreferences()
        )
    }
    .environment(\.theme, .softPaper)
    .environment(ReminderPreferences())
    .environment(CycleService(provider: MockCycleDataProvider()))
    .modelContainer(for: SymptomEntry.self, inMemory: true)
}
