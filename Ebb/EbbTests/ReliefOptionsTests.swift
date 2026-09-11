import Testing
@testable import Ebb

@Suite("ReliefOptions")
struct ReliefOptionsTests {
    let schema = try! SchemaConfig.load(from: .main)

    @Test func allCombinesSchemaAndCustomOptions() {
        let custom = [CustomReliefOption(key: "custom_abc", label: "Magnesium")]
        let all = ReliefOptions.all(from: schema, customReliefs: custom)
        #expect(all.count == 10)
        #expect(all.last?.key == "custom_abc")
        #expect(all.last?.label == "Magnesium")
    }

    @Test func existingKeyMatchesSchemaLabelCaseInsensitively() {
        let key = ReliefOptions.existingKey(
            forLabel: "HEAT PACK",
            schema: schema,
            customReliefs: []
        )
        #expect(key == "heat_pack")
    }
}
