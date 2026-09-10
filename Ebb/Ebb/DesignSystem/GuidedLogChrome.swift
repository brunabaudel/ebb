import SwiftUI

/// Soft paper 01.2 guided-log chrome — mirrors `g-strip`, `review-card` in
/// `docs/symptom-tracker-soft-paper-01-2-full.html`.
extension View {
    /// Floating card for the live sentence strip (`g-strip`).
    func guidedSentenceStrip() -> some View {
        modifier(GuidedSentenceStripModifier())
    }

    /// Review summary card (`review-card`) — shadow only, no stroke.
    func guidedReviewCard() -> some View {
        modifier(GuidedReviewCardModifier())
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

private struct GuidedReviewCardModifier: ViewModifier {
    @Environment(\.theme) private var theme

    func body(content: Content) -> some View {
        content
            .background(theme.surface, in: RoundedRectangle(cornerRadius: 20))
            .shadow(
                color: Color.black.opacity(theme.isLight ? 0.12 : 0),
                radius: 11,
                y: 4
            )
    }
}
