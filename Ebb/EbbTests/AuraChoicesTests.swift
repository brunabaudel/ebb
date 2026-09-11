import Testing
@testable import Ebb

@Suite("AuraChoices")
struct AuraChoicesTests {
    @Test func selectingNoneClearsOtherAuraTypes() {
        #expect(AuraChoices.toggle(in: ["visual", "sensory"], optionKey: "none") == ["none"])
    }

    @Test func selectingOtherAuraTypeClearsNone() {
        #expect(AuraChoices.toggle(in: ["none"], optionKey: "visual") == ["visual"])
    }

    @Test func multipleAuraTypesCanCoexist() {
        #expect(AuraChoices.toggle(in: ["visual"], optionKey: "sensory") == ["visual", "sensory"])
    }

    @Test func deselectingOptionRemovesOnlyThatKey() {
        #expect(AuraChoices.toggle(in: ["visual", "sensory"], optionKey: "visual") == ["sensory"])
    }

    @Test func deselectingNoneClearsField() {
        #expect(AuraChoices.toggle(in: ["none"], optionKey: "none") == nil)
    }

    @Test func selectingNoneFromEmpty() {
        #expect(AuraChoices.toggle(in: [], optionKey: "none") == ["none"])
    }
}
