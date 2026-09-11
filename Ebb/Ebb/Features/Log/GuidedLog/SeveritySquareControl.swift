import SwiftUI

/// Numbered square severity picker — Soft paper `.sev` grid (not slider).
struct SeveritySquareControl: View {
    let range: ClosedRange<Int>
    let labels: [Int: String]
    @Binding var selection: Int?
    let accent: FieldAccent

    @Environment(\.theme) private var theme

    private var hasVisibleCaption: Bool {
        guard let selection else { return false }
        return labels[selection] != nil
    }

    private var captionText: String {
        guard let selection, let caption = labels[selection] else { return " " }
        return caption
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 5) {
                ForEach(Array(range), id: \.self) { step in
                    squareButton(for: step)
                        .frame(maxWidth: .infinity)
                }
            }
            .frame(maxWidth: .infinity)

            Text(captionText)
                .font(.system(size: 13))
                .foregroundStyle(theme.muted)
                .opacity(hasVisibleCaption ? 1 : 0)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 18)
                .accessibilityHidden(true)
        }
        .accessibilityElement(children: .contain)
    }

    private func squareButton(for step: Int) -> some View {
        let style = squareStyle(for: step)

        return Button {
            selection = selection == step ? nil : step
        } label: {
            Text("\(step)")
                .font(.system(size: style.fontSize, weight: style.fontWeight))
                .frame(maxWidth: .infinity)
                .frame(minHeight: 44)
                .aspectRatio(1, contentMode: .fit)
                .foregroundStyle(style.foreground)
                .background {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(style.background)
                }
                .overlay {
                    if style.showsBorder {
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(theme.line, lineWidth: 1)
                    }
                }
                .shadow(
                    color: style.shadow ? accent.accentColor(in: theme).opacity(0.45) : .clear,
                    radius: 5,
                    y: 3
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel(for: step, isSelected: selection == step))
        .accessibilityAddTraits(selection == step ? .isSelected : [])
    }

    private struct SquareStyle {
        let background: Color
        let foreground: Color
        let fontSize: CGFloat
        let fontWeight: Font.Weight
        let showsBorder: Bool
        let shadow: Bool
    }

    private func squareStyle(for step: Int) -> SquareStyle {
        guard let selection else {
            return SquareStyle(
                background: theme.paper,
                foreground: theme.muted,
                fontSize: 17,
                fontWeight: .medium,
                showsBorder: true,
                shadow: false
            )
        }

        if step == selection {
            return SquareStyle(
                background: accent.accentColor(in: theme),
                foreground: accent.onAccentColor(in: theme),
                fontSize: 20,
                fontWeight: .semibold,
                showsBorder: false,
                shadow: true
            )
        }

        if step < selection {
            return SquareStyle(
                background: accent.dimColor(in: theme),
                foreground: accent.accentColor(in: theme),
                fontSize: 18,
                fontWeight: .semibold,
                showsBorder: false,
                shadow: false
            )
        }

        return SquareStyle(
            background: theme.paper,
            foreground: theme.muted,
            fontSize: 17,
            fontWeight: .medium,
            showsBorder: true,
            shadow: false
        )
    }

    private func accessibilityLabel(for step: Int, isSelected: Bool) -> String {
        let caption = labels[step].map { ", \($0)" } ?? ""
        let base = "Severity level \(step) of \(range.upperBound)\(caption)"
        return isSelected ? "\(base), selected" : base
    }
}

#Preview {
    @Previewable @State var severity: Int? = 3
    SeveritySquareControl(
        range: 1...5,
        labels: [1: "barely there", 3: "moderate", 5: "disabling"],
        selection: $severity,
        accent: .pain
    )
    .padding()
    .background(Theme.softPaper.base)
    .environment(\.theme, .softPaper)
}
