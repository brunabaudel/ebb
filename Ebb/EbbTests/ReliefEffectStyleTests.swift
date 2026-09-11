import SwiftUI
import Testing
@testable import Ebb

@Suite("ReliefEffectStyle")
struct ReliefEffectStyleTests {
    @Test("Maps relief effect keys to semantic theme tokens")
    func colorMapping() {
        let theme = Theme.softPaper
        #expect(ReliefEffectStyle.color(for: "full", in: theme) == theme.ok)
        #expect(ReliefEffectStyle.color(for: "partial", in: theme) == theme.warmInk)
        #expect(ReliefEffectStyle.color(for: "none", in: theme) == theme.pain)
    }

    @Test("Unknown effect keys fall back to muted")
    func unknownEffectKey() {
        let theme = Theme.plumEmber
        #expect(ReliefEffectStyle.color(for: "unexpected", in: theme) == theme.muted)
    }
}
