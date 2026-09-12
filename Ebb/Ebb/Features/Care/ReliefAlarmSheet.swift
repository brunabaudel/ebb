import SwiftUI

struct ReliefAlarmSheetItem: Identifiable, Equatable {
    let key: String
    let label: String

    var id: String { key }
}

struct ReliefAlarmSheet: View {
    let item: ReliefAlarmSheetItem
    @Bindable var medicationPreferences: MedicationPreferences

    var onSave: () -> Void
    var onRemoveMedicine: () -> Void

    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTime: Date

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

        var components = DateComponents()
        if let alarm = medicationPreferences.alarmTime(for: item.key) {
            components.hour = alarm.hour
            components.minute = alarm.minute
        } else {
            components.hour = ReminderPreferences.defaultReminderHour
            components.minute = ReminderPreferences.defaultReminderMinute
        }
        _selectedTime = State(initialValue: Calendar.current.date(from: components) ?? .now)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                DatePicker(
                    "Alarm time",
                    selection: $selectedTime,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .padding(.top, 8)

                VStack(spacing: 10) {
                    if medicationPreferences.alarmTime(for: item.key) != nil {
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
                .padding(.horizontal, 4)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
            .navigationTitle(item.label)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await ReminderScheduler.requestAuthorizationIfNeeded()
                            let parts = Calendar.current.dateComponents([.hour, .minute], from: selectedTime)
                            medicationPreferences.setAlarmTime(
                                for: item.key,
                                hour: parts.hour ?? ReminderPreferences.defaultReminderHour,
                                minute: parts.minute ?? ReminderPreferences.defaultReminderMinute
                            )
                            onSave()
                            dismiss()
                        }
                    }
                }
            }
        }
        .themeSettingsScreen()
        .presentationDetents([.medium])
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
    preferences.setAlarmTime(for: "ibuprofen", hour: 8, minute: 30)
    return ReliefAlarmSheet(
        item: ReliefAlarmSheetItem(key: "ibuprofen", label: "Ibuprofen"),
        medicationPreferences: preferences,
        onSave: {},
        onRemoveMedicine: {}
    )
    .environment(\.theme, .softPaper)
}
