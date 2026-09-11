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
                        myRemindersCard

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

    private var myRemindersCard: some View {
        NavigationLink {
            remindersSettings
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "bell")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(theme.pain)
                    .frame(width: 40, height: 40)
                    .background(theme.painDim, in: RoundedRectangle(cornerRadius: 12))
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 8) {
                    Text("My reminders")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(theme.text)

                    if activeReminderItems.isEmpty {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("None on")
                            Text("Turn one on to get a reminder.")
                        }
                        .font(.footnote)
                        .foregroundStyle(theme.muted)
                    } else {
                        VStack(alignment: .leading, spacing: 0) {
                            VStack(alignment: .leading, spacing: 6) {
                                ForEach(activeReminderItems) { item in
                                    Text(item.title)
                                        .font(.footnote)
                                        .foregroundStyle(theme.muted)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }

                            Text(sharedReminderTimeCaption)
                                .font(.caption)
                                .foregroundStyle(theme.muted)
                                .padding(.top, 10)
                        }
                    }
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(theme.muted)
                    .padding(.top, 4)
                    .accessibilityHidden(true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .themeCard(padding: 16, cornerRadius: theme.cardCornerRadius)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(myRemindersAccessibilityLabel)
        }
        .buttonStyle(.plain)
    }

    private var activeReminderItems: [ActiveReminderItem] {
        var items: [ActiveReminderItem] = []
        if reminderPreferences.periodStartNudgeEnabled {
            items.append(ActiveReminderItem(id: "period", title: "Period starting"))
        }
        if reminderPreferences.ovulationNudgeEnabled {
            items.append(ActiveReminderItem(id: "ovulation", title: "Estimated ovulation"))
        }
        if reminderPreferences.lutealNudgeEnabled {
            items.append(ActiveReminderItem(id: "luteal", title: "Luteal-window heads-up"))
        }
        if reminderPreferences.dailyLogReminderEnabled {
            items.append(ActiveReminderItem(id: "daily", title: "Daily log reminder"))
        }
        return items
    }

    private var sharedReminderTimeCaption: String {
        "Usually at \(reminderPreferences.reminderTimeFormatted)"
    }

    private var myRemindersAccessibilityLabel: String {
        if activeReminderItems.isEmpty {
            return "My reminders. None on. Turn one on to get a reminder."
        }
        let titles = activeReminderItems
            .map(\.title)
            .joined(separator: ". ")
        return "My reminders. \(titles). \(sharedReminderTimeCaption)"
    }

    private var remindersSettings: some View {
        RemindersSettingsView(
            schema: schema,
            reminderPreferences: reminderPreferences
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

private struct ActiveReminderItem: Identifiable {
    let id: String
    let title: String
}

#Preview("Default reminders") {
    CareView(schema: try! SchemaConfig.load())
        .environment(\.theme, .softPaper)
        .environment(MedicationPreferences())
        .environment(ReminderPreferences())
}

#Preview("Cycle nudges on") {
    let preferences = ReminderPreferences()
    preferences.periodStartNudgeEnabled = true
    return CareView(schema: try! SchemaConfig.load())
        .environment(\.theme, .softPaper)
        .environment(MedicationPreferences())
        .environment(preferences)
}

#Preview("All reminders on") {
    let preferences = ReminderPreferences()
    preferences.periodStartNudgeEnabled = true
    preferences.ovulationNudgeEnabled = true
    preferences.lutealNudgeEnabled = true
    preferences.dailyLogReminderEnabled = true
    return CareView(schema: try! SchemaConfig.load())
        .environment(\.theme, .softPaper)
        .environment(MedicationPreferences())
        .environment(preferences)
}

#Preview("None on") {
    let preferences = ReminderPreferences()
    preferences.lutealNudgeEnabled = false
    preferences.ovulationNudgeEnabled = false
    return CareView(schema: try! SchemaConfig.load())
        .environment(\.theme, .softPaper)
        .environment(MedicationPreferences())
        .environment(preferences)
}
