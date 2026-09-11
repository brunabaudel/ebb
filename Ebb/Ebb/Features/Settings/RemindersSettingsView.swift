import SwiftData
import SwiftUI

private enum ReminderTileLayout {
    static let size: CGFloat = 104
    static let gutter: CGFloat = 10
    static let cornerRadius: CGFloat = 24
}

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
                Grid(horizontalSpacing: ReminderTileLayout.gutter, verticalSpacing: ReminderTileLayout.gutter) {
                    GridRow {
                        reminderTile(
                            title: "Period starting",
                            isOn: $reminderPreferences.periodStartNudgeEnabled
                        )
                        reminderTile(
                            title: "Estimated ovulation",
                            isOn: $reminderPreferences.ovulationNudgeEnabled
                        )
                    }
                    GridRow {
                        reminderTile(
                            title: "Luteal-window heads-up",
                            isOn: $reminderPreferences.lutealNudgeEnabled
                        )
                        reminderTile(
                            title: "Daily log reminder",
                            isOn: $reminderPreferences.dailyLogReminderEnabled
                        )
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 4)
            }
            .listRowBackground(theme.base)
            .listRowSeparator(.hidden)
            .listSectionSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))

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

    private func reminderTile(title: String, isOn: Binding<Bool>) -> some View {
        let tileOn = isOn.wrappedValue
        let cornerRadius = max(ReminderTileLayout.cornerRadius, theme.cardCornerRadius)
        return Button {
            isOn.wrappedValue.toggle()
            rescheduleReminders()
        } label: {
            Text(title)
                .font(.footnote.weight(tileOn ? .semibold : .regular))
                .foregroundStyle(tileOn ? theme.text : theme.muted)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
                .padding(.horizontal, 8)
                .frame(width: ReminderTileLayout.size, height: ReminderTileLayout.size)
                .background {
                    if tileOn {
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
                    if tileOn {
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
                .shadow(color: tileOn ? theme.pain.opacity(0.32) : .clear, radius: 10, y: 3)
                .shadow(color: tileOn ? theme.pain.opacity(0.12) : .clear, radius: 2, y: 1)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityValue(tileOn ? "On" : "Off")
        .accessibilityAddTraits(tileOn ? [.isSelected] : [])
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

#Preview("Default") {
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
    .environment(CycleService(provider: MockCycleDataProvider.lutealSample()))
    .modelContainer(for: SymptomEntry.self, inMemory: true)
}
