import Testing
@testable import Ebb

@Suite("ReliefEffects")
struct ReliefEffectsTests {
    let schema = try! SchemaConfig.load(from: .main)

    @Test func resolvesPerItemMap() {
        let values: [String: FieldValue] = [
            "relief_taken": .choices(["ibuprofen", "rest_dark_room"]),
            "relief_effects": .stringMap(["ibuprofen": "partial", "rest_dark_room": "full"]),
        ]
        #expect(ReliefEffects.effect(for: "ibuprofen", in: values) == "partial")
        #expect(ReliefEffects.effect(for: "rest_dark_room", in: values) == "full")
        #expect(ReliefEffects.hasFullRelief(in: values))
    }

    @Test func legacySingleChoiceAppliesToAllTaken() {
        let values: [String: FieldValue] = [
            "relief_taken": .choices(["ibuprofen", "naproxen"]),
            "relief_effect": .choice("partial"),
        ]
        #expect(ReliefEffects.effect(for: "ibuprofen", in: values) == "partial")
        #expect(ReliefEffects.effect(for: "naproxen", in: values) == "partial")
        #expect(!ReliefEffects.hasFullRelief(in: values))
    }

    @Test func writeClearsLegacyEffect() {
        var values: [String: FieldValue] = [
            "relief_taken": .choices(["ibuprofen"]),
            "relief_effect": .choice("partial"),
        ]
        ReliefEffects.write(["ibuprofen": "full"], to: &values, schema: schema)
        #expect(values["relief_effect"] == nil)
        #expect(values["relief_effects"] == .stringMap(["ibuprofen": "full"]))
    }
}
