import XCTest
@testable import Ebb

final class LogSymptomsFlowStepTests: XCTestCase {
    func testQuestionStepsWithHeadacheIncludesRelief() {
        let steps = LogSymptomsFlowStep.questionSteps(hasHeadache: true)
        XCTAssertEqual(steps, [
            .headachePresent, .severity, .location, .qualityAndMovement,
            .relief, .cycleAndContext, .review,
        ])
    }

    func testQuestionStepsWithoutHeadacheSkipsMigraineDetailsAndRelief() {
        let steps = LogSymptomsFlowStep.questionSteps(hasHeadache: false)
        XCTAssertEqual(steps, [.headachePresent, .cycleAndContext, .review])
        XCTAssertFalse(steps.contains(.relief))
        XCTAssertFalse(steps.contains(.severity))
        XCTAssertFalse(steps.contains(.location))
        XCTAssertFalse(steps.contains(.qualityAndMovement))
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
        let sentence = LogSymptomsSentenceBuilder.segments(values: values, schema: schema)
            .map(\.text)
            .joined()
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .whitespaces)
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

    func testNoHeadacheSegmentsSkipReliefPlaceholder() {
        let values: [String: FieldValue] = [
            "migraine_present": .boolean(false),
        ]
        let segments = LogSymptomsSentenceBuilder.segments(values: values, schema: schema)
        let ids = Set(segments.map(\.id))
        XCTAssertTrue(ids.contains("migraine_present"))
        XCTAssertTrue(ids.contains("bleeding"))
        XCTAssertFalse(ids.contains("relief_taken"))
        XCTAssertFalse(ids.contains("relief_effect"))
    }

    func testUnsetFieldLabelsWithoutHeadacheOmitsRelief() {
        let values: [String: FieldValue] = [
            "migraine_present": .boolean(false),
        ]
        let unset = LogSymptomsSentenceBuilder.unsetFieldLabels(values: values, schema: schema)
        let labels = unset.map(\.label)
        XCTAssertFalse(labels.contains("Relief taken"))
        XCTAssertFalse(labels.contains("Did it help?"))
        XCTAssertTrue(labels.contains("Bleeding"))
    }

    func testFilledDetailRowsWithHeadache() {
        let values: [String: FieldValue] = [
            "migraine_present": .boolean(true),
            "severity": .scale(2),
            "location": .choices(["left", "right"]),
            "quality": .choices(["throbbing"]),
            "worse_with_movement": .boolean(true),
            "relief_taken": .choices(["ibuprofen"]),
            "relief_effect": .choice("partial"),
            "bleeding": .choice("spotting"),
            "cramps_severity": .scale(1),
            "triggers": .choices(["poor_sleep"]),
        ]
        let rows = LogSymptomsSentenceBuilder.filledDetailRows(values: values, schema: schema)
        let ids = rows.map(\.id)
        XCTAssertEqual(ids, [
            "migraine_present", "severity", "location", "quality",
            "worse_with_movement", "relief_taken", "bleeding", "cramps_severity", "triggers",
        ])
        XCTAssertTrue(rows.first(where: { $0.id == "relief_taken" })?.value.contains("Ibuprofen") == true)
        XCTAssertTrue(rows.first(where: { $0.id == "relief_taken" })?.value.contains("Some relief") == true)
    }

    func testFilledDetailRowsWithoutHeadacheOmitsPainFields() {
        let values: [String: FieldValue] = [
            "migraine_present": .boolean(false),
            "bleeding": .choice("none"),
        ]
        let rows = LogSymptomsSentenceBuilder.filledDetailRows(values: values, schema: schema)
        let ids = Set(rows.map(\.id))
        XCTAssertTrue(ids.contains("migraine_present"))
        XCTAssertTrue(ids.contains("bleeding"))
        XCTAssertFalse(ids.contains("severity"))
        XCTAssertFalse(ids.contains("relief_taken"))
    }
}
