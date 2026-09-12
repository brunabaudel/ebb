import SwiftUI

struct ReliefAlarmSheetItem: Identifiable, Equatable {
    let key: String
    let label: String

    var id: String { key }
}

private struct ReliefAlarmDraft {
    var selectedTime: Date
    var repeatPreset: ReliefRepeatPreset
    var weekdays: Set<Int>
    var startDate: Date
    var isOngoing: Bool
    var endDate: Date

    init(schedule: ReliefAlarmSchedule?) {
        let calendar = Calendar.ebbCalendar
        var timeComponents = DateComponents()
        if let schedule {
            timeComponents.hour = schedule.hour
            timeComponents.minute = schedule.minute
        } else {
            timeComponents.hour = ReminderPreferences.defaultReminderHour
            timeComponents.minute = ReminderPreferences.defaultReminderMinute
        }
        selectedTime = calendar.date(from: timeComponents) ?? .now

        if let schedule {
            repeatPreset = schedule.repeatPreset
            weekdays = schedule.weekdays
            startDate = schedule.startDate
            isOngoing = schedule.endDate == nil
            endDate = schedule.endDate ?? calendar.startOfDay(for: .now)
        } else {
            repeatPreset = .daily
            weekdays = ReliefRepeatPreset.daily.weekdays()
            startDate = calendar.startOfDay(for: .now)
            isOngoing = true
            endDate = calendar.startOfDay(for: .now)
        }
    }

    func makeSchedule(calendar: Calendar = .ebbCalendar) -> ReliefAlarmSchedule {
        let parts = calendar.dateComponents([.hour, .minute], from: selectedTime)
        let resolvedWeekdays: Set<Int> = switch repeatPreset {
        case .daily:
            ReliefAlarmSchedule.allWeekdays
        case .weekdays:
            ReliefAlarmSchedule.weekdayPreset
        case .custom:
            weekdays
        }

        return ReliefAlarmSchedule(
            hour: parts.hour ?? ReminderPreferences.defaultReminderHour,
            minute: parts.minute ?? ReminderPreferences.defaultReminderMinute,
            weekdays: resolvedWeekdays,
            startDate: calendar.startOfDay(for: startDate),
            endDate: isOngoing ? nil : calendar.startOfDay(for: endDate)
        )
    }
}

struct ReliefAlarmSheet: View {
    let item: ReliefAlarmSheetItem
    @Bindable var medicationPreferences: MedicationPreferences

    var onSave: () -> Void
    var onRemoveMedicine: () -> Void

    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss
    @State private var draft: ReliefAlarmDraft

    init(
        item: ReliefAlarmSheetItem,
        medicationPreferences: MedicationPreferences,
        onSave: @escaping () -> Void,
        onRemoveMedicine: @escaping () -> Void
    ) {
        self.item = item
        self.medicationPreferences = medicationPreferences
        self.onSave = onSave
        self.onRemoveMedicine = onRemoveMedicine
        _draft = State(
            initialValue: ReliefAlarmDraft(
                schedule: medicationPreferences.alarmSchedule(for: item.key)
            )
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    timeSection
                    repeatSection
                    if draft.repeatPreset == .custom {
                        customDaysSection
                    }
                    startDateSection
                    endDateSection
                    actionButtons
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .navigationTitle(item.label)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveSchedule() }
                        .disabled(!canSave)
                }
            }
        }
        .themeSettingsScreen()
        .presentationDetents([.medium, .large])
    }

    private var canSave: Bool {
        if draft.repeatPreset == .custom {
            return !draft.weekdays.isEmpty
        }
        if !draft.isOngoing {
            let calendar = Calendar.ebbCalendar
            return calendar.startOfDay(for: draft.endDate) >= calendar.startOfDay(for: draft.startDate)
        }
        return true
    }

    private var timeSection: some View {
        DatePicker(
            "Alarm time",
            selection: $draft.selectedTime,
            displayedComponents: .hourAndMinute
        )
        .datePickerStyle(.compact)
        .themeCard(padding: 16, cornerRadius: theme.cardCornerRadius)
    }

    private var repeatSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("Repeat")
            Picker("Repeat", selection: $draft.repeatPreset) {
                ForEach(ReliefRepeatPreset.allCases) { preset in
                    Text(preset.title).tag(preset)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: draft.repeatPreset) { _, preset in
                switch preset {
                case .daily:
                    draft.weekdays = ReliefAlarmSchedule.allWeekdays
                case .weekdays:
                    draft.weekdays = ReliefAlarmSchedule.weekdayPreset
                case .custom:
                    break
                }
            }
        }
        .themeCard(padding: 16, cornerRadius: theme.cardCornerRadius)
    }

    private var customDaysSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("Days")
            ReliefWeekdayPicker(selection: $draft.weekdays)
        }
        .themeCard(padding: 16, cornerRadius: theme.cardCornerRadius)
    }

    private var startDateSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Start date")
            DatePicker(
                "Start date",
                selection: $draft.startDate,
                in: Date.distantPast...Date.distantFuture,
                displayedComponents: .date
            )
            .datePickerStyle(.compact)
        }
        .themeCard(padding: 16, cornerRadius: theme.cardCornerRadius)
    }

    private var endDateSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("End")
            Toggle(isOn: $draft.isOngoing) {
                Text("Ongoing")
            }
            .tint(theme.ok)

            if !draft.isOngoing {
                DatePicker(
                    "End date",
                    selection: $draft.endDate,
                    in: draft.startDate...Date.distantFuture,
                    displayedComponents: .date
                )
                .datePickerStyle(.compact)
            }
        }
        .themeCard(padding: 16, cornerRadius: theme.cardCornerRadius)
    }

    private var actionButtons: some View {
        VStack(spacing: 10) {
            if medicationPreferences.alarmSchedule(for: item.key) != nil {
                Button("Remove alarm") {
                    medicationPreferences.clearAlarm(for: item.key)
                    onSave()
                    dismiss()
                }
                .buttonStyle(SoftPaperSecondaryButtonStyle())
            }

            Button("Remove \(item.label)", role: .destructive) {
                medicationPreferences.removeRelief(key: item.key)
                onRemoveMedicine()
                dismiss()
            }
            .buttonStyle(SoftPaperDestructiveButtonStyle())
        }
        .padding(.top, 4)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(theme.text)
    }

    private func saveSchedule() {
        Task {
            _ = await ReminderScheduler.requestAuthorizationForScheduling()
            medicationPreferences.setAlarmSchedule(
                for: item.key,
                schedule: draft.makeSchedule()
            )
            onSave()
            dismiss()
        }
    }
}

private struct ReliefWeekdayPicker: View {
    @Binding var selection: Set<Int>
    @Environment(\.theme) private var theme

    private let calendar = Calendar.ebbCalendar

    private var orderedWeekdays: [Int] {
        (0..<7).map { offset in
            ((calendar.firstWeekday - 1 + offset) % 7) + 1
        }
    }

    var body: some View {
        HStack(spacing: 6) {
            ForEach(orderedWeekdays, id: \.self) { weekday in
                let isSelected = selection.contains(weekday)
                Button {
                    toggle(weekday)
                } label: {
                    Text(symbol(for: weekday))
                        .font(.caption.weight(isSelected ? .semibold : .regular))
                        .foregroundStyle(isSelected ? theme.text : theme.muted)
                        .frame(maxWidth: .infinity)
                        .frame(height: 34)
                        .background {
                            Circle()
                                .fill(isSelected ? theme.pain.opacity(0.18) : theme.base)
                        }
                        .overlay {
                            Circle()
                                .strokeBorder(isSelected ? theme.pain.opacity(0.45) : theme.line, lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(fullName(for: weekday))
                .accessibilityAddTraits(isSelected ? [.isSelected] : [])
            }
        }
    }

    private func toggle(_ weekday: Int) {
        if selection.contains(weekday) {
            selection.remove(weekday)
        } else {
            selection.insert(weekday)
        }
    }

    private func symbol(for weekday: Int) -> String {
        let index = (weekday - calendar.firstWeekday + 7) % 7
        return calendar.veryShortWeekdaySymbols[index].uppercased()
    }

    private func fullName(for weekday: Int) -> String {
        calendar.weekdaySymbols[weekday - 1]
    }
}

private struct SoftPaperSecondaryButtonStyle: ButtonStyle {
    @Environment(\.theme) private var theme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.medium))
            .foregroundStyle(theme.text)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(theme.surface, in: RoundedRectangle(cornerRadius: theme.cardCornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: theme.cardCornerRadius)
                    .strokeBorder(theme.line, lineWidth: 1)
            }
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

private struct SoftPaperDestructiveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.medium))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

#Preview {
    let preferences = MedicationPreferences()
    preferences.setAlarmSchedule(
        for: "ibuprofen",
        schedule: ReliefAlarmSchedule(
            hour: 21,
            minute: 0,
            weekdays: ReliefAlarmSchedule.weekdayPreset,
            startDate: .now,
            endDate: nil
        )
    )
    return ReliefAlarmSheet(
        item: ReliefAlarmSheetItem(key: "ibuprofen", label: "Ibuprofen"),
        medicationPreferences: preferences,
        onSave: {},
        onRemoveMedicine: {}
    )
    .environment(\.theme, .softPaper)
}
