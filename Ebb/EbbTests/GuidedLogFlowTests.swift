import XCTest
@testable import Ebb

final class LogEntrySuggestionEngineTests: XCTestCase {
    private let schema = try! SchemaConfig.load()
    private let calendar = Calendar.ebbCalendar

    func testSuggestRequiresTwoPhaseMigraines() throws {
        let anchor = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 6, day: 1)))
        let overlay = CalendarCycleOverlay(
            calendar: calendar,
            cycleLength: 28,
            periodLength: 5,
            loggedPeriodDays: [anchor],
            anchorPeriodStart: anchor
        )
        let lutealDay = try XCTUnwrap(calendar.date(byAdding: .day, value: 22, to: anchor))

        let entries = [
            makeMigraine(on: lutealDay, location: ["right"], severity: 3),
        ]

        let suggestion = LogEntrySuggestionEngine.suggest(
            entries: entries,
            schema: schema,
            overlay: overlay,
            now: lutealDay
        )
        XCTAssertNil(suggestion)
    }

    func testSuggestReturnsPreFillFromSimilarEntries() throws {
        let anchor = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 6, day: 1)))
        let overlay = CalendarCycleOverlay(
            calendar: calendar,
            cycleLength: 28,
            periodLength: 5,
            loggedPeriodDays: [anchor],
            anchorPeriodStart: anchor
        )
        let day22 = try XCTUnwrap(calendar.date(byAdding: .day, value: 21, to: anchor))
        let day23 = try XCTUnwrap(calendar.date(byAdding: .day, value: 22, to: anchor))

        let entries = [
            makeMigraine(on: day22, location: ["right"], severity: 3, quality: ["throbbing"], triggers: ["poor_sleep"]),
            makeMigraine(on: day23, location: ["right"], severity: 4, quality: ["throbbing"], triggers: ["poor_sleep"]),
        ]

        let suggestion = try XCTUnwrap(
            LogEntrySuggestionEngine.suggest(
                entries: entries,
                schema: schema,
                overlay: overlay,
                now: day23
            )
        )

        XCTAssertEqual(suggestion.fieldValues["migraine_present"], .boolean(true))
        XCTAssertEqual(suggestion.fieldValues["location"], .choices(["right"]))
        XCTAssertEqual(suggestion.fieldValues["quality"], .choices(["throbbing"]))
        XCTAssertEqual(suggestion.fieldValues["triggers"], .choices(["poor_sleep"]))
        if case .scale(let step)? = suggestion.fieldValues["severity"] {
            XCTAssertEqual(step, 3)
        } else {
            XCTFail("Expected severity scale")
        }
        XCTAssertTrue(suggestion.bannerText.contains("luteal"))
    }

    private func makeMigraine(
        on date: Date,
        location: [String],
        severity: Int,
        quality: [String] = [],
        triggers: [String] = []
    ) -> SymptomEntry {
        var fields: [String: FieldValue] = [
            "migraine_present": .boolean(true),
            "severity": .scale(severity),
            "location": .choices(location),
        ]
        if !quality.isEmpty { fields["quality"] = .choices(quality) }
        if !triggers.isEmpty { fields["triggers"] = .choices(triggers) }
        return SymptomEntry(
            timestamp: date,
            schemaVersion: schema.schemaVersion,
            fieldValues: fields,
            cyclePhase: .luteal
        )
    }
}

final class LogSymptomsSentenceBuilderTests: XCTestCase {
    private let schema = try! SchemaConfig.load()

    func testReviewSentenceWithHeadache() {
        let values: [String: FieldValue] = [
            "migraine_present": .boolean(true),
            "severity": .scale(3),
            "location": .choices(["right"]),
            "quality": .choices(["throbbing"]),
            "triggers": .choices(["poor_sleep"]),
        ]
        let sentence = LogSymptomsSentenceBuilder.reviewSentence(values: values, schema: schema)
        XCTAssertTrue(sentence.contains("3/5"))
        XCTAssertTrue(sentence.localizedCaseInsensitiveContains("throbbing"))
        XCTAssertTrue(sentence.localizedCaseInsensitiveContains("right"))
        XCTAssertTrue(sentence.localizedCaseInsensitiveContains("poor sleep"))
    }

    func testSegmentsIncludeAllGuidedFields() {
        let values: [String: FieldValue] = [
            "migraine_present": .boolean(true),
            "severity": .scale(2),
            "location": .choices(["right"]),
            "quality": .choices(["dull"]),
            "worse_with_movement": .boolean(true),
            "relief_taken": .choices(["ibuprofen"]),
            "relief_effect": .choice("partial"),
            "bleeding": .choice("spotting"),
            "cramps_severity": .scale(2),
            "triggers": .choices(["stress"]),
        ]
        let segments = LogSymptomsSentenceBuilder.segments(values: values, schema: schema)
        let ids = Set(segments.map(\.id))
        XCTAssertTrue(ids.contains("severity"))
        XCTAssertTrue(ids.contains("location"))
        XCTAssertTrue(ids.contains("quality"))
        XCTAssertTrue(ids.contains("worse_with_movement"))
        XCTAssertTrue(ids.contains("relief_taken"))
        XCTAssertTrue(ids.contains("relief_effect"))
        XCTAssertTrue(ids.contains("bleeding"))
        XCTAssertTrue(ids.contains("cramps_severity"))
        XCTAssertTrue(ids.contains("triggers"))
    }
}
