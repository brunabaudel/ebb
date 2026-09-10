import SwiftUI

/// Soft paper 01.2 guided-log chrome — mirrors `g-strip` and compact review detail
/// card (sketch C) in `docs/symptom-tracker-soft-paper-01-2-full.html`.
extension View {
    /// Floating card for the live sentence strip (`g-strip`).
    func guidedSentenceStrip() -> some View {
        modifier(GuidedSentenceStripModifier())
    }

    /// Compact review detail card (sketch C) — soft paper surface, hairline border.
    func guidedReviewDetailCard() -> some View {
        modifier(GuidedReviewDetailCardModifier())
    }
}

private struct GuidedSentenceStripModifier: ViewModifier {
    @Environment(\.theme) private var theme

    func body(content: Content) -> some View {
        content
            .background(theme.surface, in: RoundedRectangle(cornerRadius: 14))
            .shadow(color: Color.black.opacity(theme.isLight ? 0.08 : 0), radius: 6, y: 3)
    }
}

private struct GuidedReviewDetailCardModifier: ViewModifier {
    @Environment(\.theme) private var theme

    func body(content: Content) -> some View {
        content
            .background(theme.surface, in: RoundedRectangle(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(theme.line, lineWidth: 1)
            }
    }
}
