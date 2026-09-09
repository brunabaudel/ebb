import SwiftUI

/// Contextual unlock moment (paywall frame A) — shown when Patterns has real data.
struct PatternsPaywallView: View {
    @Environment(\.theme) private var theme
    let onUnlock: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Your patterns")
                .font(.system(.title2, design: .serif))

            Text("Enough data — here's what we found.")
                .font(.subheadline)
                .foregroundStyle(theme.muted)
                .padding(.top, 4)

            paywallIllustration
                .padding(.top, 16)

            blurredPreview
                .padding(.top, 18)

            featureList
                .padding(.top, 22)

            Button(action: onUnlock) {
                Text("Unlock Ebb+")
                    .font(.body.weight(.bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
            }
            .buttonStyle(.plain)
            .foregroundStyle(theme.onPain)
            .background(theme.pain, in: RoundedRectangle(cornerRadius: 16))
            .padding(.top, 24)

            Text("7-day free trial · keep logging free forever")
                .font(.caption)
                .foregroundStyle(theme.muted)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
                .padding(.top, 11)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 24)
    }

    private var paywallIllustration: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [theme.surface, theme.painDim.opacity(0.55)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)
                    .shadow(color: theme.cardShadowColor, radius: 8, y: 4)

                EbbMascot(variant: .default, size: 52)
            }

            Text("Patterns, doctor PDF, full history — still private, still on your phone.")
                .font(.system(.subheadline, design: .serif))
                .italic()
                .foregroundStyle(theme.text.opacity(0.88))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [theme.surface, theme.painDim.opacity(0.35)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: theme.cardCornerRadius)
        )
        .overlay {
            RoundedRectangle(cornerRadius: theme.cardCornerRadius)
                .strokeBorder(theme.line, lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Ebb. Patterns, doctor PDF, and full history stay private on your phone.")
    }

    private var blurredPreview: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 14) {
                Text("Migraines by cycle phase")
                    .font(.caption)
                    .foregroundStyle(theme.muted)

                HStack(alignment: .bottom, spacing: 8) {
                    ForEach([0.30, 0.18, 0.24, 0.88, 0.74, 0.62], id: \.self) { fraction in
                        RoundedRectangle(cornerRadius: 5)
                            .fill(
                                LinearGradient(
                                    colors: [theme.pain, theme.painDim],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(height: 74 * fraction)
                    }
                }
                .frame(height: 74)

                RoundedRectangle(cornerRadius: 5)
                    .fill(theme.cycleDim)
                    .frame(height: 10)
                RoundedRectangle(cornerRadius: 5)
                    .fill(theme.cycleDim)
                    .frame(width: 200, height: 10)
            }
            .padding(18)
            .blur(radius: 5)
            .opacity(0.55)
            .accessibilityHidden(true)

            VStack(spacing: 8) {
                Image(systemName: "lock.fill")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(theme.pain)
                    .frame(width: 42, height: 42)
                    .background(theme.painDim, in: Circle())
                    .overlay {
                        Circle().strokeBorder(theme.pain, lineWidth: 1)
                    }

                Text("See what's triggering them")
                    .font(.system(.subheadline, design: .serif))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                LinearGradient(
                    colors: [.clear, theme.surface.opacity(0.95)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .themeCard(padding: 18)
    }

    private var featureList: some View {
        VStack(alignment: .leading, spacing: 13) {
            paywallFeature(
                title: "Trigger correlation",
                detail: "what actually precedes your attacks"
            )
            paywallFeature(
                title: "Luteal-window forecast",
                detail: "see the next high-risk days coming"
            )
            paywallFeature(
                title: "Doctor-ready PDF",
                detail: "bring the pattern to your GP"
            )
        }
    }

    private func paywallFeature(title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 11) {
            Text("✓")
                .font(.footnote.weight(.bold))
                .foregroundStyle(theme.pain)
            Text(attributedFeature(title: title, detail: detail))
                .font(.footnote)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func attributedFeature(title: String, detail: String) -> AttributedString {
        var result = AttributedString("\(title) — \(detail)")
        if let range = result.range(of: title) {
            result[range].font = .footnote.weight(.semibold)
            result[range].foregroundColor = theme.text
        }
        if let range = result.range(of: "— \(detail)") {
            result[range].foregroundColor = theme.muted
        }
        return result
    }
}

#Preview {
    ScrollView {
        PatternsPaywallView(onUnlock: {})
    }
    .background(Theme.plumEmber.base)
    .environment(\.theme, .plumEmber)
}
