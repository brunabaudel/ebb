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

struct ReminderTileGrid: View {
    @Bindable var preferences: ReminderPreferences
    var onToggle: () -> Void

    @Environment(\.theme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let rowVerticalPadding: CGFloat = 13

    var body: some View {
        VStack(spacing: 0) {
            reminderRow(
                title: "Period starting",
                isOn: $preferences.periodStartNudgeEnabled
            )
            reminderHairline
            reminderRow(
                title: "Estimated ovulation",
                isOn: $preferences.ovulationNudgeEnabled
            )
            reminderHairline
            reminderRow(
                title: "Luteal-window heads-up",
                isOn: $preferences.lutealNudgeEnabled
            )
            reminderHairline
            reminderRow(
                title: "Daily log reminder",
                isOn: $preferences.dailyLogReminderEnabled
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var reminderHairline: some View {
        Rectangle()
            .fill(theme.pain.opacity(0.35))
            .frame(height: 1)
    }

    private func reminderRow(title: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: animatedBinding(isOn)) {
            Text(title)
                .font(.body)
                .foregroundStyle(isOn.wrappedValue ? theme.text : theme.muted)
        }
        .tint(theme.ok)
        .padding(.vertical, rowVerticalPadding)
    }

    private func animatedBinding(_ isOn: Binding<Bool>) -> Binding<Bool> {
        Binding(
            get: { isOn.wrappedValue },
            set: { newValue in
                let apply = {
                    isOn.wrappedValue = newValue
                    onToggle()
                }
                if reduceMotion {
                    apply()
                } else {
                    withAnimation(.smooth(duration: 0.28)) {
                        apply()
                    }
                }
            }
        )
    }
}

struct ReminderTimeRow: View {
    @Bindable var preferences: ReminderPreferences
    var onTap: () -> Void

    @Environment(\.theme) private var theme

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 10) {
                Rectangle()
                    .fill(theme.pain.opacity(0.35))
                    .frame(height: 1)

                Text("Remind at")
                    .font(.caption)
                    .foregroundStyle(theme.muted)

                Text(preferences.reminderTimeFormatted)
                    .font(.title3)
                    .fontWeight(.medium)
                    .monospacedDigit()
                    .foregroundStyle(theme.warmInk)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Remind at \(preferences.reminderTimeFormatted)")
        .accessibilityHint("Opens reminder time picker")
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
                "",
                selection: $selectedTime,
                displayedComponents: .hourAndMinute
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .frame(maxWidth: .infinity)
            .padding(.horizontal)
            .padding(.bottom, 8)
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

#Preview("Reminder journal rows") {
    ReminderTileGrid(preferences: ReminderPreferences()) {}
        .padding(20)
        .background(Theme.softPaper.base)
        .environment(\.theme, .softPaper)
}

#Preview("Reminder time row") {
    ReminderTimeRow(preferences: ReminderPreferences()) {}
        .padding(20)
        .background(Theme.softPaper.base)
        .environment(\.theme, .softPaper)
}

#Preview("Reminder time picker") {
    ReminderTimePickerSheet(preferences: ReminderPreferences()) {}
        .environment(\.theme, .softPaper)
}
