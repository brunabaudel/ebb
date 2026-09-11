import SwiftData
import SwiftUI

/// Pushed doctor-export screen; Care inlines `DoctorExportContent` directly.
struct DoctorExportView: View {
    let schema: SchemaConfig

    var body: some View {
        ScrollView {
            DoctorExportContent(schema: schema)
                .padding(.top, 4)
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
        }
        .themeSettingsScreen()
        .navigationTitle("Bring to your doctor")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview("With data") {
    let schema = try! SchemaConfig.load()
    let container = try! ModelContainer(
        for: SymptomEntry.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let cal = Calendar.ebbCalendar
    let periodStart = cal.date(from: DateComponents(year: 2026, month: 6, day: 1))!

    container.mainContext.insert(SymptomEntry(
        timestamp: periodStart,
        schemaVersion: schema.schemaVersion,
        fieldValues: ["bleeding": .choice("medium")]
    ))
    for day in [17, 20, 25] {
        let date = cal.date(byAdding: .day, value: day - 1, to: periodStart)!
        container.mainContext.insert(SymptomEntry(
            timestamp: cal.date(bySettingHour: 20, minute: 0, second: 0, of: date)!,
            schemaVersion: schema.schemaVersion,
            fieldValues: [
                "migraine_present": .boolean(true),
                "severity": .scale(4),
                "location": .choices(["right"]),
                "triggers": .choices(["poor_sleep", "stress"]),
                "relief_taken": .choices(["ibuprofen"]),
                "relief_effect": .choice("partial"),
            ],
            cyclePhase: .luteal
        ))
    }

    return NavigationStack {
        DoctorExportView(schema: schema)
    }
    .modelContainer(container)
    .environment(\.theme, .plumEmber)
    .environment(CycleService(provider: MockCycleDataProvider()))
    .environment(MedicationPreferences())
    .environment(EntitlementsService(previewIsEbbPlus: true, listenForUpdates: false))
}

#Preview("Empty") {
    NavigationStack {
        DoctorExportView(schema: try! SchemaConfig.load())
    }
    .modelContainer(for: SymptomEntry.self, inMemory: true)
    .environment(\.theme, .plumEmber)
    .environment(CycleService(provider: MockCycleDataProvider()))
    .environment(MedicationPreferences())
    .environment(EntitlementsService(previewIsEbbPlus: false, listenForUpdates: false))
}
