import SwiftUI

/// Soft paper 01.2 guided-log chrome — compact review detail card (sketch C) in
/// `docs/symptom-tracker-soft-paper-01-2-full.html`.
extension View {
    /// Compact review detail card (sketch C) — soft paper surface, hairline border.
    func guidedReviewDetailCard() -> some View {
        modifier(GuidedReviewDetailCardModifier())
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
