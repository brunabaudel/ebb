import SwiftData
import SwiftUI

struct CareView: View {
    let schema: SchemaConfig

    @Environment(\.theme) private var theme
    @Environment(MedicationPreferences.self) private var medicationPreferences
    @Environment(ReminderPreferences.self) private var reminderPreferences
    @Environment(CycleService.self) private var cycleService
    @Query(sort: \SymptomEntry.timestamp, order: .reverse) private var entries: [SymptomEntry]

    @State private var showTimePicker = false

    var body: some View {
        @Bindable var reminderPreferences = reminderPreferences
        @Bindable var medicationPreferences = medicationPreferences

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header
                        .padding(.bottom, 24)

                    VStack(spacing: 14) {
                        myRemindersSection(
                            reminderPreferences: reminderPreferences
                        )

                        myMedicationsSection(
                            medicationPreferences: medicationPreferences
                        )

                        bringToDoctorSection
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .background(theme.base)
            .foregroundStyle(theme.text)
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showTimePicker) {
                ReminderTimePickerSheet(preferences: reminderPreferences) {
                    rescheduleReminders()
                }
            }
            .task {
                rescheduleReminders()
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Care")
                .font(.system(.title, design: .serif))
            Text("Reminders, medications, and a note for your doctor.")
                .font(.footnote)
                .foregroundStyle(theme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func myRemindersSection(
        reminderPreferences: ReminderPreferences
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("My reminders")
                .font(.body.weight(.semibold))
                .foregroundStyle(theme.text)

            ReminderTileGrid(preferences: reminderPreferences) {
                rescheduleReminders()
            }

            if reminderPreferences.hasAnyNudgeEnabled {
                ReminderTimeRow(
                    preferences: reminderPreferences,
                    onTap: { showTimePicker = true }
                )
                .themeCard(padding: 16, cornerRadius: theme.cardCornerRadius)
            }

            ReminderPauseDuringMigraineToggle(
                preferences: reminderPreferences,
                onChange: rescheduleReminders
            )
            .themeCard(padding: 16, cornerRadius: theme.cardCornerRadius)
        }
    }

    private func myMedicationsSection(
        medicationPreferences: MedicationPreferences
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("My medications")
                .font(.body.weight(.semibold))
                .foregroundStyle(theme.text)

            MedicationTileGrid(
                schema: schema,
                medicationPreferences: medicationPreferences
            )
        }
    }

    private var bringToDoctorSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Bring to your doctor")
                .font(.body.weight(.semibold))
                .foregroundStyle(theme.text)

            DoctorExportContent(schema: schema)
        }
    }

    private func rescheduleReminders() {
        ReminderScheduling.reschedule(
            preferences: reminderPreferences,
            cycleService: cycleService,
            entries: entries
        )
    }
}

#Preview("Default") {
    CareView(schema: try! SchemaConfig.load())
        .environment(\.theme, .softPaper)
        .environment(MedicationPreferences())
        .environment(ReminderPreferences())
        .environment(CycleService(provider: MockCycleDataProvider.lutealSample()))
        .environment(EntitlementsService(previewIsEbbPlus: false, listenForUpdates: false))
        .modelContainer(for: SymptomEntry.self, inMemory: true)
}

#Preview("Some reminders on") {
    let preferences = ReminderPreferences()
    preferences.periodStartNudgeEnabled = true
    preferences.lutealNudgeEnabled = true
    return CareView(schema: try! SchemaConfig.load())
        .environment(\.theme, .softPaper)
        .environment(MedicationPreferences())
        .environment(preferences)
        .environment(CycleService(provider: MockCycleDataProvider.lutealSample()))
        .environment(EntitlementsService(previewIsEbbPlus: false, listenForUpdates: false))
        .modelContainer(for: SymptomEntry.self, inMemory: true)
}

#Preview("Saved medications") {
    let medications = MedicationPreferences()
    medications.setSaved("ibuprofen", isSaved: true)
    medications.setSaved("triptan", isSaved: true)
    return CareView(schema: try! SchemaConfig.load())
        .environment(\.theme, .softPaper)
        .environment(medications)
        .environment(ReminderPreferences())
        .environment(CycleService(provider: MockCycleDataProvider.lutealSample()))
        .environment(EntitlementsService(previewIsEbbPlus: false, listenForUpdates: false))
        .modelContainer(for: SymptomEntry.self, inMemory: true)
}
