import SwiftUI

/// Semantic colors for `relief_effect` keys (`none` / `partial` / `full`).
enum ReliefEffectStyle {
    static func color(for effectKey: String, in theme: Theme) -> Color {
        switch effectKey {
        case "full": theme.ok
        case "partial": theme.warmInk
        case "none": theme.pain
        default: theme.muted
        }
    }

    static func onColor(for effectKey: String, in theme: Theme) -> Color {
        switch effectKey {
        case "full": theme.surface
        case "partial", "none": theme.onPain
        default: theme.text
        }
    }

    static func dimColor(for effectKey: String, in theme: Theme) -> Color {
        switch effectKey {
        case "full": theme.cycleDim
        case "partial": theme.painDim.opacity(theme.isLight ? 0.85 : 1)
        case "none": theme.painDim
        default: theme.surface
        }
    }

    static func foregroundColor(for effectKey: String, isSelected: Bool, in theme: Theme) -> Color {
        if isSelected {
            onColor(for: effectKey, in: theme)
        } else {
            color(for: effectKey, in: theme).opacity(theme.isLight ? 0.72 : 0.82)
        }
    }

    static func backgroundColor(for effectKey: String, isSelected: Bool, in theme: Theme) -> Color {
        if isSelected {
            color(for: effectKey, in: theme)
        } else {
            dimColor(for: effectKey, in: theme)
        }
    }

    static func borderColor(for effectKey: String, isSelected: Bool, in theme: Theme) -> Color {
        let base = color(for: effectKey, in: theme)
        return isSelected ? base : base.opacity(theme.isLight ? 0.42 : 0.55)
    }
}

/// One line in a review detail card; relief rows carry an optional effect key for coloring.
struct ReviewValueLine: Equatable, Sendable {
    let prefix: String
    let effectLabel: String?
    let reliefEffectKey: String?

    var displayText: String {
        if let effectLabel {
            return "\(prefix) · \(effectLabel)"
        }
        return prefix
    }
}

/// Renders one relief summary line with the effect portion color-coded.
struct ReliefValueLineText: View {
    let line: ReviewValueLine
    let defaultInk: Color

    @Environment(\.theme) private var theme

    var body: some View {
        Group {
            if let effectKey = line.reliefEffectKey, let effectLabel = line.effectLabel {
                (Text(line.prefix + " · ")
                    .foregroundStyle(defaultInk)
                 + Text(effectLabel)
                    .foregroundStyle(ReliefEffectStyle.color(for: effectKey, in: theme)))
            } else {
                Text(line.displayText)
                    .foregroundStyle(defaultInk)
            }
        }
        .fontWeight(.semibold)
        .multilineTextAlignment(.trailing)
    }
}

/// Shared value column for review detail rows (entry overview + guided review).
struct ReviewDetailValue: View {
    let row: ReviewDetailRow

    @Environment(\.theme) private var theme

    var body: some View {
        let ink = row.accent == .cycle ? theme.coolInk : theme.warmInk
        if let lines = row.valueLines, !lines.isEmpty {
            VStack(alignment: .trailing, spacing: 4) {
                ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                    ReliefValueLineText(line: line, defaultInk: ink)
                }
            }
        } else {
            Text(row.value)
                .fontWeight(.semibold)
                .foregroundStyle(ink)
                .multilineTextAlignment(.trailing)
        }
    }
}

/// “Did it help?” chip with per-effect semantic coloring.
struct ReliefEffectPill: View {
    let label: String
    let effectKey: String
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.theme) private var theme

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline.weight(isSelected ? .semibold : .regular))
                .foregroundStyle(ReliefEffectStyle.foregroundColor(for: effectKey, isSelected: isSelected, in: theme))
                .padding(.horizontal, theme.chipHorizontalPadding)
                .padding(.vertical, theme.chipVerticalPadding)
                .background(
                    ReliefEffectStyle.backgroundColor(for: effectKey, isSelected: isSelected, in: theme),
                    in: Capsule()
                )
                .overlay {
                    Capsule()
                        .strokeBorder(
                            ReliefEffectStyle.borderColor(for: effectKey, isSelected: isSelected, in: theme),
                            lineWidth: 1
                        )
                }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityLabel(label)
    }
}

#Preview("Relief effect pills") {
    VStack(spacing: 12) {
        HStack {
            ReliefEffectPill(label: "No relief", effectKey: "none", isSelected: false) {}
            ReliefEffectPill(label: "No relief", effectKey: "none", isSelected: true) {}
        }
        HStack {
            ReliefEffectPill(label: "Some relief", effectKey: "partial", isSelected: false) {}
            ReliefEffectPill(label: "Some relief", effectKey: "partial", isSelected: true) {}
        }
        HStack {
            ReliefEffectPill(label: "Full relief", effectKey: "full", isSelected: false) {}
            ReliefEffectPill(label: "Full relief", effectKey: "full", isSelected: true) {}
        }
    }
    .padding()
    .background(Theme.softPaper.base)
    .environment(\.theme, .softPaper)
}
