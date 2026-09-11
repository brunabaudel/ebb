import Foundation
import Testing
@testable import Ebb

@Suite("DaySummaryBuilder")
struct DaySummaryBuilderTests {
    let schema = try! SchemaConfig.load(from: .main)
    let calendar = Calendar(identifier: .gregorian)
    let today = Calendar(identifier: .gregorian).date(from: DateComponents(year: 2026, month: 7, day: 4, hour: 14))!

    @Test func todayRowMarkersMatchTimelineChips() {
        let migraine = SymptomEntry(
            timestamp: today,
            schemaVersion: schema.schemaVersion,
            fieldValues: [
                "migraine_present": .boolean(true),
                "severity": .scale(4),
                "location": .choices(["right"]),
                "associated_symptoms": .choices(["nausea"]),
                "relief_taken": .choices(["ibuprofen"]),
            ]
        )
        let migraineMarkers = DaySummaryBuilder.todayRowMarkers(migraine, schema: schema)
        #expect(DaySummaryBuilder.todayRowTitle(migraine, schema: schema) == "Migraine")
        #expect(migraineMarkers.map(\.label) == ["severe", "right side", "nausea", "ibuprofen"])
        #expect(migraineMarkers.map(\.kind) == [.pain, .pain, .pain, .neutral])

        let spotting = SymptomEntry(
            timestamp: today,
            schemaVersion: schema.schemaVersion,
            fieldValues: [
                "migraine_present": .boolean(false),
                "bleeding": .choice("spotting"),
                "cramps_severity": .scale(2),
            ],
            cyclePhase: .luteal
        )
        let spottingMarkers = DaySummaryBuilder.todayRowMarkers(spotting, schema: schema)
        #expect(spottingMarkers.map(\.label) == ["spotting", "mild cramps"])
        #expect(spottingMarkers.map(\.kind) == [.cycle, .cycle])

        let migraineInMenstrual = SymptomEntry(
            timestamp: today,
            schemaVersion: schema.schemaVersion,
            fieldValues: [
                "migraine_present": .boolean(true),
                "severity": .scale(3),
            ],
            cyclePhase: .menstrual
        )
        let migraineMarkersOnly = DaySummaryBuilder.todayRowMarkers(migraineInMenstrual, schema: schema)
        #expect(migraineMarkersOnly.map(\.label) == ["moderate"])
        #expect(!migraineMarkersOnly.contains(where: { $0.label == "menstrual" || $0.label == "luteal" }))
    }

    @Test func todayRowSeverityLabelForMigraineOnly() {
        let migraine = SymptomEntry(
            timestamp: today,
            schemaVersion: schema.schemaVersion,
            fieldValues: [
                "migraine_present": .boolean(true),
                "severity": .scale(3),
                "location": .choices(["right"]),
            ]
        )
        #expect(DaySummaryBuilder.todayRowSeverityLabel(migraine, schema: schema) == "moderate")
        #expect(DaySummaryBuilder.todayRowDetail(migraine, schema: schema) == "moderate")

        let spotting = SymptomEntry(
            timestamp: today,
            schemaVersion: schema.schemaVersion,
            fieldValues: [
                "migraine_present": .boolean(false),
                "bleeding": .choice("spotting"),
                "cramps_severity": .scale(2),
            ]
        )
        #expect(DaySummaryBuilder.todayRowSeverityLabel(spotting, schema: schema) == nil)
        #expect(DaySummaryBuilder.todayRowDetail(spotting, schema: schema) == nil)
    }

    @Test func todayRowTitleForCorruptEntry() {
        let entry = SymptomEntry(schemaVersion: schema.schemaVersion)
        entry.fieldValuesData = Data("{bad".utf8)

        #expect(
            DaySummaryBuilder.todayRowTitle(entry, schema: schema)
                == "Symptom log (data unreadable)"
        )
    }
}
