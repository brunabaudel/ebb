import SwiftUI

struct CareView: View {
    let schema: SchemaConfig

    @Environment(\.theme) private var theme
    @Environment(MedicationPreferences.self) private var medicationPreferences
    @Environment(ReminderPreferences.self) private var reminderPreferences

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header
                        .padding(.bottom, 24)

                    VStack(spacing: 14) {
                        remindersSection

                        careCard(
                            title: "My medications",
                            caption: "What you take with each log.",
                            systemImage: "pills"
                        ) {
                            MedicationsSettingsView(
                                schema: schema,
                                medicationPreferences: medicationPreferences
                            )
                        }

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

    private var remindersSection: some View {
        VStack(spacing: 14) {
            careCard(
                title: "My reminders",
                caption: "What's on, and when.",
                systemImage: "bell"
            ) {
                remindersSettings
            }

            reminderStatusCards
        }
    }

    @ViewBuilder
    private var reminderStatusCards: some View {
        if reminderPreferences.lutealNudgeEnabled {
            reminderStatusCard(
                title: "Luteal-window heads-up",
                caption: reminderPreferences.reminderTimeFormatted,
                systemImage: "bell.fill",
                isMuted: false
            )
        }

        if reminderPreferences.dailyLogReminderEnabled {
            reminderStatusCard(
                title: "Daily log reminder",
                caption: reminderPreferences.reminderTimeFormatted,
                systemImage: "bell.fill",
                isMuted: false
            )
        }

        if !reminderPreferences.lutealNudgeEnabled && !reminderPreferences.dailyLogReminderEnabled {
            reminderStatusCard(
                title: "None on",
                caption: "Turn one on in My reminders.",
                systemImage: "bell.slash",
                isMuted: true
            )
        }
    }

    private var remindersSettings: some View {
        RemindersSettingsView(
            schema: schema,
            reminderPreferences: reminderPreferences
        )
    }

    private func reminderStatusCard(
        title: String,
        caption: String,
        systemImage: String,
        isMuted: Bool
    ) -> some View {
        NavigationLink {
            remindersSettings
        } label: {
            careCardLabel(
                title: title,
                caption: caption,
                systemImage: systemImage,
                isMuted: isMuted
            )
        }
        .buttonStyle(.plain)
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

#Preview("Default reminders") {
    CareView(schema: try! SchemaConfig.load())
        .environment(\.theme, .softPaper)
        .environment(MedicationPreferences())
        .environment(ReminderPreferences())
}

#Preview("Both reminders on") {
    let preferences = ReminderPreferences()
    preferences.dailyLogReminderEnabled = true
    return CareView(schema: try! SchemaConfig.load())
        .environment(\.theme, .softPaper)
        .environment(MedicationPreferences())
        .environment(preferences)
}

#Preview("None on") {
    let preferences = ReminderPreferences()
    preferences.lutealNudgeEnabled = false
    return CareView(schema: try! SchemaConfig.load())
        .environment(\.theme, .softPaper)
        .environment(MedicationPreferences())
        .environment(preferences)
}
