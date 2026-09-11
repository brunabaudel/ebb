import SwiftUI

struct CareView: View {
    let schema: SchemaConfig

    @Environment(\.theme) private var theme
    @Environment(MedicationPreferences.self) private var medicationPreferences
    @Environment(ReminderPreferences.self) private var reminderPreferences

    var body: some View {
        NavigationStack {
            ScrollView {
                careLinksCard
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .background(theme.base)
            .foregroundStyle(theme.text)
            .navigationTitle("Care")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private var careLinksCard: some View {
        VStack(spacing: 0) {
            NavigationLink {
                RemindersSettingsView(
                    schema: schema,
                    reminderPreferences: reminderPreferences
                )
            } label: {
                careRow(title: "Reminders", systemImage: "bell")
            }
            .buttonStyle(.plain)

            Divider().overlay(theme.line)

            NavigationLink {
                MedicationsSettingsView(
                    schema: schema,
                    medicationPreferences: medicationPreferences
                )
            } label: {
                careRow(title: "My medications", systemImage: "pills")
            }
            .buttonStyle(.plain)

            Divider().overlay(theme.line)

            NavigationLink {
                DoctorExportView(schema: schema)
            } label: {
                careRow(title: "Bring to your doctor", systemImage: "doc.text")
            }
            .buttonStyle(.plain)
        }
        .themeCard(padding: 0, cornerRadius: theme.cardCornerRadius)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Reminders, medications, and doctor export")
    }

    private func careRow(title: String, systemImage: String) -> some View {
        HStack(spacing: 12) {
            Label {
                Text(title)
                    .font(.body)
                    .foregroundStyle(theme.text)
            } icon: {
                Image(systemName: systemImage)
                    .foregroundStyle(theme.muted)
            }
            Spacer(minLength: 8)
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(theme.muted)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }
}

#Preview {
    CareView(schema: try! SchemaConfig.load())
        .environment(\.theme, .softPaper)
        .environment(MedicationPreferences())
        .environment(ReminderPreferences())
}
