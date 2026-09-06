import XCTest
@testable import Ebb

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
}
