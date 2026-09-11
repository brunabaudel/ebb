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

    @Test func toggleTakenKeyPrunesEffectsWhenDeselected() {
        var values: [String: FieldValue] = [
            "relief_taken": .choices(["ibuprofen", "naproxen"]),
            "relief_effects": .stringMap(["ibuprofen": "partial", "naproxen": "full"]),
        ]
        ReliefEffects.toggleTakenKey("naproxen", in: &values)
        #expect(values["relief_taken"] == .choices(["ibuprofen"]))
        #expect(values["relief_effects"] == .stringMap(["ibuprofen": "partial"]))
    }

    @Test func toggleTakenKeyClearsAllReliefDataWhenEmpty() {
        var values: [String: FieldValue] = [
            "relief_taken": .choices(["ibuprofen"]),
            "relief_effects": .stringMap(["ibuprofen": "partial"]),
            "relief_effect": .choice("partial"),
        ]
        ReliefEffects.toggleTakenKey("ibuprofen", in: &values)
        #expect(values["relief_taken"] == nil)
        #expect(values["relief_effects"] == nil)
        #expect(values["relief_effect"] == nil)
    }

    @Test func toggleEffectWritesPerMedMapAndClearsLegacy() {
        var values: [String: FieldValue] = [
            "relief_taken": .choices(["ibuprofen", "naproxen"]),
            "relief_effect": .choice("partial"),
        ]
        ReliefEffects.toggleEffect(reliefKey: "ibuprofen", effectKey: "full", in: &values, schema: schema)
        ReliefEffects.toggleEffect(reliefKey: "naproxen", effectKey: "none", in: &values, schema: schema)
        #expect(values["relief_effect"] == nil)
        #expect(values["relief_effects"] == .stringMap(["ibuprofen": "full", "naproxen": "none"]))
    }

    @Test func toggleEffectDeselectsWhenSameKeyTapped() {
        var values: [String: FieldValue] = [
            "relief_taken": .choices(["ibuprofen"]),
            "relief_effects": .stringMap(["ibuprofen": "full"]),
        ]
        ReliefEffects.toggleEffect(reliefKey: "ibuprofen", effectKey: "full", in: &values, schema: schema)
        #expect(values["relief_effects"] == nil)
    }

    @Test func editRoundTripMigratesLegacyToPerMedOnEffectChange() {
        var values: [String: FieldValue] = [
            "relief_taken": .choices(["ibuprofen", "naproxen"]),
            "relief_effect": .choice("partial"),
        ]
        #expect(ReliefEffects.effect(for: "ibuprofen", in: values) == "partial")
        ReliefEffects.toggleEffect(reliefKey: "ibuprofen", effectKey: "full", in: &values, schema: schema)
        #expect(values["relief_effect"] == nil)
        #expect(values["relief_effects"] == .stringMap(["ibuprofen": "full", "naproxen": "partial"]))
    }

    @Test func sanitizedMapKeepsCustomReliefKeys() {
        var values: [String: FieldValue] = [
            "relief_taken": .choices(["custom_xyz"]),
        ]
        ReliefEffects.toggleEffect(
            reliefKey: "custom_xyz",
            effectKey: "partial",
            in: &values,
            schema: schema,
            extraReliefKeys: ["custom_xyz"]
        )
        #expect(values["relief_effects"] == .stringMap(["custom_xyz": "partial"]))
    }
}
