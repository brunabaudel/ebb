import XCTest
@testable import Ebb

final class LogSymptomsFlowStepTests: XCTestCase {
    func testQuestionStepsWithHeadacheIncludesAuraReliefAndTriggers() {
        let steps = LogSymptomsFlowStep.questionSteps(hasHeadache: true)
        XCTAssertEqual(steps, [
            .headachePresent, .location, .aura,
            .relief, .triggers, .cycleAndContext, .review,
        ])
        XCTAssertFalse(steps.contains(.severity))
    }

    func testQuestionStepsWithoutHeadacheSkipsAura() {
        let steps = LogSymptomsFlowStep.questionSteps(hasHeadache: false)
        XCTAssertFalse(steps.contains(.aura))
    }

    func testQuestionStepsWithoutHeadacheSkipsMigraineDetailsAndRelief() {
        let steps = LogSymptomsFlowStep.questionSteps(hasHeadache: false)
        XCTAssertEqual(steps, [.headachePresent, .triggers, .cycleAndContext, .review])
        XCTAssertFalse(steps.contains(.relief))
        XCTAssertFalse(steps.contains(.severity))
        XCTAssertFalse(steps.contains(.location))
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
        let reliefSegment = segments.first { $0.id == "relief_taken" }
        XCTAssertTrue(reliefSegment?.text.localizedCaseInsensitiveContains("Some relief") == true)
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
            "aura": .choices(["visual"]),
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
            "worse_with_movement", "aura", "relief_taken", "bleeding", "cramps_severity", "triggers",
        ])
        XCTAssertEqual(rows.first(where: { $0.id == "aura" })?.step, .aura)
        XCTAssertTrue(rows.first(where: { $0.id == "relief_taken" })?.value.contains("Ibuprofen") == true)
        XCTAssertTrue(rows.first(where: { $0.id == "relief_taken" })?.value.contains("Some relief") == true)
        XCTAssertEqual(rows.first(where: { $0.id == "severity" })?.step, .headachePresent)
        XCTAssertEqual(rows.first(where: { $0.id == "quality" })?.step, .headachePresent)
        XCTAssertEqual(rows.first(where: { $0.id == "worse_with_movement" })?.step, .headachePresent)
        XCTAssertEqual(rows.first(where: { $0.id == "triggers" })?.step, .triggers)
    }

    func testTriggersSegmentJumpsToTriggersStep() {
        let values: [String: FieldValue] = [
            "migraine_present": .boolean(true),
            "triggers": .choices(["stress"]),
        ]
        let segments = LogSymptomsSentenceBuilder.segments(values: values, schema: schema)
        let triggersSegment = segments.first { $0.id == "triggers" }
        XCTAssertEqual(triggersSegment?.step, .triggers)
    }

    func testUnsetTriggersJumpsToTriggersStep() {
        let values: [String: FieldValue] = [
            "migraine_present": .boolean(false),
        ]
        let unset = LogSymptomsSentenceBuilder.unsetFieldLabels(values: values, schema: schema)
        let triggers = unset.first { $0.label == "Triggers" }
        XCTAssertEqual(triggers?.step, .triggers)
    }

    func testPerReliefEffectsSummary() {
        let values: [String: FieldValue] = [
            "migraine_present": .boolean(true),
            "relief_taken": .choices(["ibuprofen", "rest_dark_room"]),
            "relief_effects": .stringMap(["ibuprofen": "partial", "rest_dark_room": "full"]),
        ]
        let rows = LogSymptomsSentenceBuilder.filledDetailRows(values: values, schema: schema)
        let relief = rows.first(where: { $0.id == "relief_taken" })?.value ?? ""
        XCTAssertTrue(relief.contains("Ibuprofen"))
        XCTAssertTrue(relief.contains("Some relief"))
        XCTAssertTrue(relief.contains("Rest"))
        XCTAssertTrue(relief.contains("Full relief"))
    }

    func testLegacySingleReliefEffectAppliesToAllTaken() {
        let values: [String: FieldValue] = [
            "migraine_present": .boolean(true),
            "relief_taken": .choices(["ibuprofen", "naproxen"]),
            "relief_effect": .choice("partial"),
        ]
        let rows = LogSymptomsSentenceBuilder.filledDetailRows(values: values, schema: schema)
        let relief = rows.first(where: { $0.id == "relief_taken" })?.value ?? ""
        XCTAssertTrue(relief.contains("Ibuprofen · Some relief"))
        XCTAssertTrue(relief.contains("Naproxen · Some relief"))
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

    func testSeveritySegmentJumpsToHeadachePresent() {
        let values: [String: FieldValue] = [
            "migraine_present": .boolean(true),
            "severity": .scale(3),
        ]
        let segments = LogSymptomsSentenceBuilder.segments(values: values, schema: schema)
        let severitySegment = segments.first { $0.id == "severity" }
        XCTAssertEqual(severitySegment?.step, .headachePresent)
    }

    func testUnsetSeverityJumpsToHeadachePresent() {
        let values: [String: FieldValue] = [
            "migraine_present": .boolean(true),
        ]
        let unset = LogSymptomsSentenceBuilder.unsetFieldLabels(values: values, schema: schema)
        let severity = unset.first { $0.label == "Severity" }
        XCTAssertEqual(severity?.step, .headachePresent)
    }

    func testQualitySegmentJumpsToHeadachePresent() {
        let values: [String: FieldValue] = [
            "migraine_present": .boolean(true),
            "quality": .choices(["throbbing"]),
        ]
        let segments = LogSymptomsSentenceBuilder.segments(values: values, schema: schema)
        let qualitySegment = segments.first { $0.id == "quality" }
        XCTAssertEqual(qualitySegment?.step, .headachePresent)
    }

    func testMovementSegmentJumpsToHeadachePresent() {
        let values: [String: FieldValue] = [
            "migraine_present": .boolean(true),
            "worse_with_movement": .boolean(true),
        ]
        let segments = LogSymptomsSentenceBuilder.segments(values: values, schema: schema)
        let movementSegment = segments.first { $0.id == "worse_with_movement" }
        XCTAssertEqual(movementSegment?.step, .headachePresent)
    }

    func testUnsetQualityAndMovementJumpToHeadachePresent() {
        let values: [String: FieldValue] = [
            "migraine_present": .boolean(true),
            "severity": .scale(2),
        ]
        let unset = LogSymptomsSentenceBuilder.unsetFieldLabels(values: values, schema: schema)
        let quality = unset.first { $0.label == "Quality" }
        let movement = unset.first { $0.label == "Worse with movement" }
        XCTAssertEqual(quality?.step, .headachePresent)
        XCTAssertEqual(movement?.step, .headachePresent)
    }

    func testAuraSegmentJumpsToAuraStep() {
        let values: [String: FieldValue] = [
            "migraine_present": .boolean(true),
            "aura": .choices(["visual", "sensory"]),
        ]
        let segments = LogSymptomsSentenceBuilder.segments(values: values, schema: schema)
        let auraSegment = segments.first { $0.id == "aura" }
        XCTAssertEqual(auraSegment?.step, .aura)
        XCTAssertTrue(auraSegment?.text.localizedCaseInsensitiveContains("visual") == true)
    }

    func testUnsetAuraJumpsToAuraStep() {
        let values: [String: FieldValue] = [
            "migraine_present": .boolean(true),
            "severity": .scale(2),
        ]
        let unset = LogSymptomsSentenceBuilder.unsetFieldLabels(values: values, schema: schema)
        let aura = unset.first { $0.label == "Aura" }
        XCTAssertEqual(aura?.step, .aura)
    }

}
