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

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        CareTileGrid(columnCount: ReminderTileGridLayout.columnCount) {
            ReminderToggleTile(
                title: "Period starting",
                isOn: animatedBinding($preferences.periodStartNudgeEnabled)
            )
            ReminderToggleTile(
                title: "Estimated ovulation",
                isOn: animatedBinding($preferences.ovulationNudgeEnabled)
            )
            ReminderToggleTile(
                title: "Luteal-window",
                accessibilityTitle: "Luteal-window heads-up",
                isOn: animatedBinding($preferences.lutealNudgeEnabled)
            )
            ReminderToggleTile(
                title: "Daily log",
                accessibilityTitle: "Daily log reminder",
                isOn: animatedBinding($preferences.dailyLogReminderEnabled)
            )
        }
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

private struct ReminderToggleTile: View {
    let title: String
    var accessibilityTitle: String?
    @Binding var isOn: Bool

    @Environment(\.theme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var label: String {
        accessibilityTitle ?? title
    }

    var body: some View {
        let cornerRadius = max(CareTileLayout.cornerRadius, theme.cardCornerRadius)

        Button {
            isOn.toggle()
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(isOn ? theme.text : theme.muted)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Spacer(minLength: 4)

                HStack(spacing: 8) {
                    Text(isOn ? "On" : "Off")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(isOn ? theme.warmInk : theme.muted)

                    Spacer(minLength: 0)

                    Toggle("", isOn: $isOn)
                        .labelsHidden()
                        .controlSize(.mini)
                        .tint(theme.ok)
                }
            }
            .padding(.top, 12)
            .padding(.horizontal, 13)
            .padding(.bottom, 11)
            .frame(maxWidth: .infinity)
            .frame(height: CareTileLayout.reminderTileHeight)
            .background {
                if isOn {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(
                            LinearGradient(
                                colors: [theme.pain.opacity(0.18), theme.pain.opacity(0.36)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                } else {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(theme.surface)
                }
            }
            .overlay {
                if isOn {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .inset(by: 0.5)
                        .stroke(
                            LinearGradient(
                                colors: [theme.surface.opacity(0.45), theme.surface.opacity(0)],
                                startPoint: .top,
                                endPoint: .center
                            ),
                            lineWidth: 1
                        )
                } else {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .strokeBorder(theme.line, lineWidth: 1)
                }
            }
            .shadow(color: isOn ? theme.pain.opacity(0.32) : .clear, radius: 10, y: 3)
            .shadow(color: isOn ? theme.pain.opacity(0.12) : .clear, radius: 2, y: 1)
        }
        .buttonStyle(.plain)
        .animation(
            reduceMotion ? nil : .smooth(duration: 0.28),
            value: isOn
        )
        .accessibilityElement(children: .ignore)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(label)
        .accessibilityValue(isOn ? "On" : "Off")
        .accessibilityAddTraits(isOn ? [.isSelected] : [])
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

#Preview("Reminder landscape cards") {
    let preferences = ReminderPreferences()
    preferences.periodStartNudgeEnabled = true
    preferences.ovulationNudgeEnabled = false
    preferences.lutealNudgeEnabled = true
    preferences.dailyLogReminderEnabled = false
    return ReminderTileGrid(preferences: preferences) {}
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
