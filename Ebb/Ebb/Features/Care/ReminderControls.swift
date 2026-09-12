import SwiftData
import SwiftUI

enum ReminderScheduling {
    @MainActor
    static func reschedule(
        preferences: ReminderPreferences,
        cycleService: CycleService,
        entries: [SymptomEntry]
    ) {
        Task { @MainActor in
            let overlay = cycleService.makeOverlay(from: entries)
            await ReminderScheduler.reschedule(
                input: ReminderScheduler.ScheduleInput(
                    preferences: preferences,
                    overlay: overlay,
                    entries: entries,
                    now: .now
                )
            )
        }
    }

    @MainActor
    static func rescheduleReliefAlarms(
        schema: SchemaConfig,
        medicationPreferences: MedicationPreferences,
        preferences: ReminderPreferences,
        entries: [SymptomEntry]
    ) {
        Task { @MainActor in
            await ReminderScheduler.rescheduleReliefAlarms(
                input: ReminderScheduler.ReliefAlarmScheduleInput(
                    medicationPreferences: medicationPreferences,
                    schema: schema,
                    preferences: preferences,
                    entries: entries,
                    now: .now
                )
            )
        }
    }

    @MainActor
    static func rescheduleAll(
        schema: SchemaConfig,
        medicationPreferences: MedicationPreferences,
        preferences: ReminderPreferences,
        cycleService: CycleService,
        entries: [SymptomEntry]
    ) {
        Task { @MainActor in
            let overlay = cycleService.makeOverlay(from: entries)
            await ReminderScheduler.reschedule(
                input: ReminderScheduler.ScheduleInput(
                    preferences: preferences,
                    overlay: overlay,
                    entries: entries,
                    now: .now
                )
            )
            await ReminderScheduler.rescheduleReliefAlarms(
                input: ReminderScheduler.ReliefAlarmScheduleInput(
                    medicationPreferences: medicationPreferences,
                    schema: schema,
                    preferences: preferences,
                    entries: entries,
                    now: .now
                )
            )
        }
    }
}

private enum ReminderTileGridLayout {
    static let columnCount = 2
}

struct ReminderTileGrid: View {
    @Bindable var preferences: ReminderPreferences
    var onToggle: () -> Void

    var body: some View {
        CareTileGrid(columnCount: ReminderTileGridLayout.columnCount) {
            reminderTile(
                title: "Period starting",
                isOn: $preferences.periodStartNudgeEnabled
            )
            reminderTile(
                title: "Estimated ovulation",
                isOn: $preferences.ovulationNudgeEnabled
            )
            reminderTile(
                title: "Luteal-window heads-up",
                isOn: $preferences.lutealNudgeEnabled
            )
            reminderTile(
                title: "Daily log reminder",
                isOn: $preferences.dailyLogReminderEnabled
            )
        }
    }

    private func reminderTile(title: String, isOn: Binding<Bool>) -> some View {
        CareSelectionTile(
            title: title,
            isSelected: isOn.wrappedValue,
            shape: .landscape()
        ) {
            isOn.wrappedValue.toggle()
            onToggle()
        }
    }
}

struct ReminderTimeRow: View {
    @Bindable var preferences: ReminderPreferences
    var onTap: () -> Void

    @Environment(\.theme) private var theme

    var body: some View {
        Button(action: onTap) {
            LabeledContent("Reminder time") {
                Text(preferences.reminderTimeFormatted)
                    .foregroundStyle(theme.muted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
    }
}

struct PauseDuringMigraineToggle: View {
    @Binding var isOn: Bool
    var onChange: () -> Void

    @Environment(\.theme) private var theme

    var body: some View {
        Toggle(isOn: $isOn) {
            Text("Quiet during a migraine")
        }
        .tint(theme.ok)
        .onChange(of: isOn) { _, _ in
            onChange()
        }
    }
}

struct ReminderPauseDuringMigraineToggle: View {
    @Bindable var preferences: ReminderPreferences
    var onChange: () -> Void

    var body: some View {
        PauseDuringMigraineToggle(isOn: $preferences.pauseDuringMigraine, onChange: onChange)
    }
}

struct ReliefPauseDuringMigraineToggle: View {
    @Bindable var medicationPreferences: MedicationPreferences
    var onChange: () -> Void

    var body: some View {
        PauseDuringMigraineToggle(
            isOn: $medicationPreferences.pauseAlarmsDuringMigraine,
            onChange: onChange
        )
    }
}

struct ReminderTimePickerSheet: View {
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
