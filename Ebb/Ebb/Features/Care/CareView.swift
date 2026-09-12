import SwiftData
import SwiftUI

struct CareView: View {
    let schema: SchemaConfig

    @Environment(\.theme) private var theme
    @Environment(MedicationPreferences.self) private var medicationPreferences
    @Environment(ReminderPreferences.self) private var reminderPreferences
    @Environment(CycleService.self) private var cycleService
    @Query(sort: \SymptomEntry.timestamp, order: .reverse) private var entries: [SymptomEntry]

    @State private var selectedTab: CareTab = .doctor
    @State private var showTimePicker = false

    var body: some View {
        @Bindable var reminderPreferences = reminderPreferences
        @Bindable var medicationPreferences = medicationPreferences
        @Bindable var cyclePreferences = cycleService.preferences

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header
                        .padding(.bottom, 24)

                    Picker("Section", selection: $selectedTab) {
                        ForEach(CareTab.segmentedTabs) { tab in
                            Text(tab.title).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .tint(theme.pain)
                    .padding(.bottom, 14)

                    selectedTabContent(
                        reminderPreferences: reminderPreferences,
                        medicationPreferences: medicationPreferences,
                        cyclePreferences: cyclePreferences
                    )
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
                    rescheduleAllReminders()
                }
            }
            .task {
                rescheduleAllReminders()
            }
        }
    }

    private var header: some View {
        Text("My care")
            .font(.system(.title, design: .serif))
            .accessibilityAddTraits(.isHeader)
    }

    @ViewBuilder
    private func selectedTabContent(
        reminderPreferences: ReminderPreferences,
        medicationPreferences: MedicationPreferences,
        cyclePreferences: CyclePreferences
    ) -> some View {
        switch selectedTab {
        case .doctor:
            DoctorExportContent(schema: schema)
        case .medications:
            reliefContent(medicationPreferences: medicationPreferences)
        case .reminders:
            remindersContent(reminderPreferences: reminderPreferences)
        case .cycle:
            CycleInfoControls(preferences: cyclePreferences)
        }
    }

    private func reliefContent(medicationPreferences: MedicationPreferences) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            ReliefPauseDuringMigraineToggle(
                medicationPreferences: medicationPreferences,
                onChange: rescheduleReliefAlarms
            )
            .themeCard(padding: 16, cornerRadius: theme.cardCornerRadius)

            Text("Set a time on a medicine. A highlighted tile means that alarm is on.")
                .font(.subheadline)
                .foregroundStyle(theme.muted)
                .frame(maxWidth: .infinity, alignment: .leading)

            MedicationTileGrid(
                schema: schema,
                medicationPreferences: medicationPreferences,
                onAlarmChange: rescheduleReliefAlarms
            )
        }
    }

    private func remindersContent(reminderPreferences: ReminderPreferences) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            ReminderPauseDuringMigraineToggle(
                preferences: reminderPreferences,
                onChange: rescheduleAllReminders
            )
            .themeCard(padding: 16, cornerRadius: theme.cardCornerRadius)

            Text("Turn on the days you want a reminder. They all fire at the time below.")
                .font(.subheadline)
                .foregroundStyle(theme.muted)
                .frame(maxWidth: .infinity, alignment: .leading)

            ReminderTileGrid(preferences: reminderPreferences) {
                rescheduleAllReminders()
            }

            if reminderPreferences.hasAnyNudgeEnabled {
                ReminderTimeRow(
                    preferences: reminderPreferences,
                    onTap: { showTimePicker = true }
                )
                .themeCard(padding: 16, cornerRadius: theme.cardCornerRadius)
            }
        }
    }

    private func rescheduleAllReminders() {
        ReminderScheduling.rescheduleAll(
            schema: schema,
            medicationPreferences: medicationPreferences,
            preferences: reminderPreferences,
            cycleService: cycleService,
            entries: entries
        )
    }

    private func rescheduleReliefAlarms() {
        ReminderScheduling.rescheduleReliefAlarms(
            schema: schema,
            medicationPreferences: medicationPreferences,
            preferences: reminderPreferences,
            entries: entries
        )
    }
}

private enum CareTab: String, CaseIterable, Identifiable {
    case doctor
    case medications
    case reminders
    case cycle

    static let segmentedTabs: [CareTab] = [.doctor, .medications, .reminders, .cycle]

    var id: String { rawValue }

    var title: String {
        switch self {
        case .doctor: "Doctor"
        case .medications: "Relief"
        case .reminders: "Reminders"
        case .cycle: "Cycle"
        }
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

#Preview("Relief with alarms") {
    let medications = MedicationPreferences()
    medications.setSaved("ibuprofen", isSaved: true)
    medications.setAlarmSchedule(
        for: "ibuprofen",
        schedule: ReliefAlarmSchedule(
            hour: 9,
            minute: 0,
            weekdays: ReliefAlarmSchedule.allWeekdays,
            startDate: .now,
            endDate: nil
        )
    )
    return CareView(schema: try! SchemaConfig.load())
        .environment(\.theme, .softPaper)
        .environment(medications)
        .environment(ReminderPreferences())
        .environment(CycleService(provider: MockCycleDataProvider.lutealSample()))
        .environment(EntitlementsService(previewIsEbbPlus: false, listenForUpdates: false))
        .modelContainer(for: SymptomEntry.self, inMemory: true)
}
