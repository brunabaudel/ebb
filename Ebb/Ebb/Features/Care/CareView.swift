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

                    SoftPaperSegmentedControl(
                        segments: CareTab.allCases.map { tab in
                            .init(id: tab, title: tab.title)
                        },
                        selection: $selectedTab
                    )
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
                    rescheduleReminders()
                }
            }
            .task {
                rescheduleReminders()
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
            MedicationTileGrid(
                schema: schema,
                medicationPreferences: medicationPreferences
            )
        case .reminders:
            remindersContent(reminderPreferences: reminderPreferences)
        case .cycle:
            CycleInfoControls(preferences: cyclePreferences)
        }
    }

    private func remindersContent(
        reminderPreferences: ReminderPreferences
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
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

    private func rescheduleReminders() {
        ReminderScheduling.reschedule(
            preferences: reminderPreferences,
            cycleService: cycleService,
            entries: entries
        )
    }
}

private enum CareTab: String, CaseIterable, Identifiable {
    case doctor
    case medications
    case reminders
    case cycle

    var id: String { rawValue }

    var title: String {
        switch self {
        case .doctor: "Doctor"
        case .medications: "Medications"
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
