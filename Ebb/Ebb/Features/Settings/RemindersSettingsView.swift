import SwiftData
import SwiftUI

struct RemindersSettingsView: View {
    let schema: SchemaConfig
    @Bindable var reminderPreferences: ReminderPreferences

    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(CycleService.self) private var cycleService
    @Query(sort: \SymptomEntry.timestamp, order: .reverse) private var entries: [SymptomEntry]

    @State private var showTimePicker = false
    #if DEBUG
    @State private var lutealTestMessage: String?
    #endif

    var body: some View {
        List {
            Section {
                Toggle(isOn: $reminderPreferences.periodStartNudgeEnabled) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Period starting")
                        Text("When your estimated period window begins.")
                            .font(.caption)
                            .foregroundStyle(theme.muted)
                    }
                }
                .themeListRow()
                .onChange(of: reminderPreferences.periodStartNudgeEnabled) { _, _ in
                    rescheduleReminders()
                }

                Toggle(isOn: $reminderPreferences.ovulationNudgeEnabled) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Estimated ovulation")
                        Text("On your estimated ovulation day.")
                            .font(.caption)
                            .foregroundStyle(theme.muted)
                    }
                }
                .themeListRow()
                .onChange(of: reminderPreferences.ovulationNudgeEnabled) { _, _ in
                    rescheduleReminders()
                }

                Toggle(isOn: $reminderPreferences.lutealNudgeEnabled) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Luteal-window heads-up")
                        Text("When your higher-risk luteal phase begins.")
                            .font(.caption)
                            .foregroundStyle(theme.muted)
                    }
                }
                .themeListRow()
                .onChange(of: reminderPreferences.lutealNudgeEnabled) { _, _ in
                    rescheduleReminders()
                }

                Toggle(isOn: $reminderPreferences.dailyLogReminderEnabled) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Daily log reminder")
                        Text("Optional check-in at a time you choose.")
                            .font(.caption)
                            .foregroundStyle(theme.muted)
                    }
                }
                .themeListRow()
                .onChange(of: reminderPreferences.dailyLogReminderEnabled) { _, _ in
                    rescheduleReminders()
                }
            }

            if reminderPreferences.hasAnyNudgeEnabled {
                Section {
                    Button {
                        showTimePicker = true
                    } label: {
                        LabeledContent("Reminder time") {
                            Text(reminderPreferences.reminderTimeFormatted)
                                .foregroundStyle(theme.muted)
                        }
                    }
                    .themeListRow()
                } header: {
                    Text("Time")
                } footer: {
                    Text("Shared by the reminders that are on.")
                }
            }

            Section {
                Toggle(isOn: $reminderPreferences.pauseDuringMigraine) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Pause reminders during a migraine")
                        Text("When a migraine is logged, reminders stay quiet until it's over.")
                            .font(.caption)
                            .foregroundStyle(theme.muted)
                    }
                }
                .themeListRow()
                .onChange(of: reminderPreferences.pauseDuringMigraine) { _, _ in
                    rescheduleReminders()
                }
            } header: {
                Text("Mid-migraine")
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
        Task {
            let overlay = cycleService.makeOverlay(from: entries)
            await ReminderScheduler.reschedule(
                input: ReminderScheduler.ScheduleInput(
                    preferences: reminderPreferences,
                    overlay: overlay,
                    entries: entries,
                    now: .now
                )
            )
        }
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

private struct ReminderTimePickerSheet: View {
    @Bindable var preferences: ReminderPreferences
    var onSave: () -> Void

    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTime: Date

    init(preferences: ReminderPreferences, onSave: @escaping () -> Void) {
        self.preferences = preferences
        self.onSave = onSave
        var components = DateComponents()
        components.hour = preferences.reminderHour
        components.minute = preferences.reminderMinute
        _selectedTime = State(initialValue: Calendar.current.date(from: components) ?? .now)
    }

    var body: some View {
        NavigationStack {
            DatePicker(
                "Reminder time",
                selection: $selectedTime,
                displayedComponents: .hourAndMinute
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .padding()
            .navigationTitle("Reminder time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let parts = Calendar.current.dateComponents([.hour, .minute], from: selectedTime)
                        preferences.reminderHour = parts.hour ?? ReminderPreferences.defaultReminderHour
                        preferences.reminderMinute = parts.minute ?? ReminderPreferences.defaultReminderMinute
                        onSave()
                        dismiss()
                    }
                }
            }
        }
        .themeSettingsScreen()
        .presentationDetents([.medium])
    }
}

#Preview {
    NavigationStack {
        RemindersSettingsView(
            schema: try! SchemaConfig.load(),
            reminderPreferences: ReminderPreferences()
        )
    }
    .environment(\.theme, .softPaper)
    .environment(CycleService(provider: MockCycleDataProvider.lutealSample()))
    .modelContainer(for: SymptomEntry.self, inMemory: true)
}
