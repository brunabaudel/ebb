import SwiftData
import SwiftUI

private enum ReminderTileLayout {
    static let referenceSize: CGFloat = 104
    static let gutter: CGFloat = 10
    static let cornerRadius: CGFloat = 24

    struct Metrics {
        let tile: CGFloat
        let gutter: CGFloat
        let timeSide: CGFloat

        var gridHeight: CGFloat { 2 * tile + gutter }
    }

    /// `2×tile + 3×gutter + timeSide = available`, with `timeSide = 2×tile + gutter`.
    static func metrics(forAvailableWidth width: CGFloat) -> Metrics {
        let gutter = Self.gutter
        let tile = max(0, (width - 3 * gutter) / 4)
        let timeSide = 2 * tile + gutter
        return Metrics(tile: tile, gutter: gutter, timeSide: timeSide)
    }

    static func scaledCornerRadius(tile: CGFloat, theme: Theme) -> CGFloat {
        let scale = tile / referenceSize
        let scaled = cornerRadius * scale
        return max(scaled, theme.cardCornerRadius)
    }
}

struct RemindersSettingsView: View {
    let schema: SchemaConfig
    @Bindable var reminderPreferences: ReminderPreferences

    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(CycleService.self) private var cycleService
    @Query(sort: \SymptomEntry.timestamp, order: .reverse) private var entries: [SymptomEntry]

    @State private var showTimePicker = false
    @State private var availableGridWidth: CGFloat = 358
    #if DEBUG
    @State private var lutealTestMessage: String?
    #endif

    var body: some View {
        List {
            Section {
                reminderTilesAndTimeRow
                    .padding(.vertical, 4)
                    .background {
                        GeometryReader { geometry in
                            Color.clear
                                .onAppear {
                                    availableGridWidth = geometry.size.width
                                }
                                .onChange(of: geometry.size.width) { _, newWidth in
                                    availableGridWidth = newWidth
                                }
                        }
                    }
            }
            .listRowBackground(theme.base)
            .listRowSeparator(.hidden)
            .listSectionSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))

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

    private var reminderTilesAndTimeRow: some View {
        let metrics = ReminderTileLayout.metrics(forAvailableWidth: availableGridWidth)
        let cornerRadius = ReminderTileLayout.scaledCornerRadius(tile: metrics.tile, theme: theme)

        return HStack(spacing: metrics.gutter) {
            Grid(horizontalSpacing: metrics.gutter, verticalSpacing: metrics.gutter) {
                GridRow {
                    reminderTile(
                        title: "Period starting",
                        isOn: $reminderPreferences.periodStartNudgeEnabled,
                        tileSize: metrics.tile,
                        cornerRadius: cornerRadius
                    )
                    reminderTile(
                        title: "Estimated ovulation",
                        isOn: $reminderPreferences.ovulationNudgeEnabled,
                        tileSize: metrics.tile,
                        cornerRadius: cornerRadius
                    )
                }
                GridRow {
                    reminderTile(
                        title: "Luteal-window heads-up",
                        isOn: $reminderPreferences.lutealNudgeEnabled,
                        tileSize: metrics.tile,
                        cornerRadius: cornerRadius
                    )
                    reminderTile(
                        title: "Daily log reminder",
                        isOn: $reminderPreferences.dailyLogReminderEnabled,
                        tileSize: metrics.tile,
                        cornerRadius: cornerRadius
                    )
                }
            }

            timeSquare(size: metrics.timeSide, cornerRadius: cornerRadius)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .frame(height: metrics.gridHeight)
    }

    private func reminderTile(
        title: String,
        isOn: Binding<Bool>,
        tileSize: CGFloat,
        cornerRadius: CGFloat
    ) -> some View {
        let tileOn = isOn.wrappedValue
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
                .frame(width: tileSize, height: tileSize)
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

    private func timeSquare(size: CGFloat, cornerRadius: CGFloat) -> some View {
        Button {
            showTimePicker = true
        } label: {
            VStack(spacing: 6) {
                Text("Time")
                    .font(.caption)
                    .foregroundStyle(theme.muted)
                Text(reminderPreferences.reminderTimeFormatted)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(theme.text)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
            }
            .frame(width: size, height: size)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [theme.ok.opacity(0.22), theme.ok.opacity(0.40)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            .overlay {
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
            }
            .shadow(color: theme.ok.opacity(0.32), radius: 10, y: 3)
            .shadow(color: theme.ok.opacity(0.12), radius: 2, y: 1)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Time, \(reminderPreferences.reminderTimeFormatted)")
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
