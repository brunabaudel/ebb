import SwiftData
import SwiftUI

struct CareView: View {
    let schema: SchemaConfig

    @Environment(\.theme) private var theme
    @Environment(MedicationPreferences.self) private var medicationPreferences
    @Environment(ReminderPreferences.self) private var reminderPreferences
    @Environment(CycleService.self) private var cycleService
    @Query(sort: \SymptomEntry.timestamp, order: .reverse) private var entries: [SymptomEntry]

    @State private var showTimePicker = false

    var body: some View {
        @Bindable var reminderPreferences = reminderPreferences
        @Bindable var medicationPreferences = medicationPreferences

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header
                        .padding(.bottom, 24)

                    VStack(spacing: 14) {
                        myRemindersSection(
                            reminderPreferences: reminderPreferences
                        )

                        myMedicationsSection(
                            medicationPreferences: medicationPreferences
                        )

                        careCard(
                            title: "Bring to your doctor",
                            caption: "A PDF of your history.",
                            systemImage: "doc.text"
                        ) {
                            DoctorExportView(schema: schema)
                        }
                    }
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
        VStack(alignment: .leading, spacing: 4) {
            Text("Care")
                .font(.system(.title, design: .serif))
            Text("Reminders, medications, and a note for your doctor.")
                .font(.footnote)
                .foregroundStyle(theme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func myRemindersSection(
        reminderPreferences: ReminderPreferences
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("My reminders")
                .font(.body.weight(.semibold))
                .foregroundStyle(theme.text)

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

    private func myMedicationsSection(
        medicationPreferences: MedicationPreferences
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("My medications")
                .font(.body.weight(.semibold))
                .foregroundStyle(theme.text)

            MedicationTileGrid(
                schema: schema,
                medicationPreferences: medicationPreferences
            )
        }
    }

    private func rescheduleReminders() {
        ReminderScheduling.reschedule(
            preferences: reminderPreferences,
            cycleService: cycleService,
            entries: entries
        )
    }

    private func careCard<Destination: View>(
        title: String,
        caption: String,
        systemImage: String,
        @ViewBuilder destination: () -> Destination
    ) -> some View {
        NavigationLink {
            destination()
        } label: {
            careCardLabel(title: title, caption: caption, systemImage: systemImage)
        }
        .buttonStyle(.plain)
    }

    private func careCardLabel(
        title: String,
        caption: String,
        systemImage: String,
        isMuted: Bool = false
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(isMuted ? theme.muted : theme.pain)
                .frame(width: 40, height: 40)
                .background(theme.painDim, in: RoundedRectangle(cornerRadius: 12))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(isMuted ? theme.muted : theme.text)
                Text(caption)
                    .font(.footnote)
                    .foregroundStyle(theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(theme.muted)
                .accessibilityHidden(true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .themeCard(padding: 16, cornerRadius: theme.cardCornerRadius)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(caption)")
    }
}

#Preview("Default") {
    CareView(schema: try! SchemaConfig.load())
        .environment(\.theme, .softPaper)
        .environment(MedicationPreferences())
        .environment(ReminderPreferences())
        .environment(CycleService(provider: MockCycleDataProvider.lutealSample()))
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
        .modelContainer(for: SymptomEntry.self, inMemory: true)
}
