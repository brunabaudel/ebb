import SwiftData
import SwiftUI

struct RemindersSettingsView: View {
    let schema: SchemaConfig
    @Bindable var reminderPreferences: ReminderPreferences

    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(CycleService.self) private var cycleService
    @Environment(MedicationPreferences.self) private var medicationPreferences
    @Query(sort: \SymptomEntry.timestamp, order: .reverse) private var entries: [SymptomEntry]

    @State private var showTimePicker = false
    #if DEBUG
    @State private var lutealTestMessage: String?
    #endif

    var body: some View {
        List {
            Section {
                ReminderTileGrid(preferences: reminderPreferences) {
                    rescheduleReminders()
                }
                .padding(.vertical, 4)
            }
            .listRowBackground(theme.base)
            .listRowSeparator(.hidden)
            .listSectionSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))

            if reminderPreferences.hasAnyNudgeEnabled {
                Section {
                    ReminderTimeRow(preferences: reminderPreferences) {
                        showTimePicker = true
                    }
                    .themeListRow()
                } footer: {
                    Text("Shared by the reminders that are on.")
                }
            }

            Section {
                ReminderPauseDuringMigraineToggle(
                    preferences: reminderPreferences,
                    onChange: rescheduleReminders
                )
                .themeListRow()
            }

            #if DEBUG
            lutealTestSection
            #endif
        }
        .themeSettingsList()
        .navigationTitle("My reminders")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showTimePicker) {
            ReminderTimePickerSheet(preferences: reminderPreferences) {
                rescheduleReminders()
            }
        }
        .task {
            rescheduleReminders()
        }
    }

    private func rescheduleReminders() {
        ReminderScheduling.rescheduleAll(
            schema: schema,
            medicationPreferences: medicationPreferences,
            preferences: reminderPreferences,
            cycleService: cycleService,
            entries: entries
        )
    }

    #if DEBUG
    private var lutealTestSection: some View {
        Section {
            Text("Inserts a 5-day period starting 14 days ago so today is luteal day 15. Then set reminder time 1–2 minutes ahead, turn off daily log, and background the app.")
                .font(.footnote)
                .foregroundStyle(theme.muted)
                .themeListRow()

            Button("Seed mock period for luteal test") {
                seedLutealTestData()
            }
            .themeListRow()

            if let lutealTestMessage {
                Text(lutealTestMessage)
                    .font(.footnote)
                    .foregroundStyle(theme.ok)
                    .fixedSize(horizontal: false, vertical: true)
                    .themeListRow()
            }
        } header: {
            Text("Testing")
        }
    }

    private func seedLutealTestData() {
        lutealTestMessage = nil
        do {
            let result = try LutealTestDataSeeder.seed(
                schemaVersion: schema.schemaVersion,
                modelContext: modelContext,
                cycleService: cycleService
            )
            let dateLabel = result.nextLutealStart.formatted(date: .abbreviated, time: .omitted)
            lutealTestMessage =
                "Seeded. Today is cycle day \(result.cycleDayToday) (\(result.phaseToday.displayName)). Next luteal heads-up: \(dateLabel)."
            rescheduleReminders()
        } catch {
            lutealTestMessage = error.localizedDescription
        }
    }
    #endif
}

#Preview("Default") {
    NavigationStack {
        RemindersSettingsView(
            schema: try! SchemaConfig.load(),
            reminderPreferences: ReminderPreferences()
        )
    }
    .environment(\.theme, .softPaper)
    .environment(MedicationPreferences())
    .environment(CycleService(provider: MockCycleDataProvider.lutealSample()))
    .modelContainer(for: SymptomEntry.self, inMemory: true)
}

#Preview("Some on") {
    let preferences = ReminderPreferences()
    preferences.periodStartNudgeEnabled = true
    preferences.lutealNudgeEnabled = true
    return NavigationStack {
        RemindersSettingsView(
            schema: try! SchemaConfig.load(),
            reminderPreferences: preferences
        )
    }
    .environment(\.theme, .softPaper)
    .environment(MedicationPreferences())
    .environment(CycleService(provider: MockCycleDataProvider.lutealSample()))
    .modelContainer(for: SymptomEntry.self, inMemory: true)
}
