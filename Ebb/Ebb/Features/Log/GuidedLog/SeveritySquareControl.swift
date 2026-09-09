import SwiftUI

/// Numbered square severity picker for the guided flow (replaces slider mockup K).
struct SeveritySquareControl: View {
    let range: ClosedRange<Int>
    let labels: [Int: String]
    @Binding var selection: Int?
    let accent: FieldAccent

    @Environment(\.theme) private var theme

    private var cornerRadius: CGFloat {
        theme.isLight ? 12 : 10
    }

    private var squareSpacing: CGFloat {
        theme.isLight ? 11 : 8
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: squareSpacing) {
                ForEach(Array(range), id: \.self) { step in
                    squareButton(for: step)
                        .frame(maxWidth: .infinity)
                }
            }
            .frame(maxWidth: .infinity)

            if let selection, let caption = labels[selection] {
                Text(caption)
                    .font(.subheadline)
                    .foregroundStyle(theme.muted)
                    .italic()
                    .accessibilityHidden(true)
            }
        }
        .accessibilityElement(children: .contain)
    }

    private func squareButton(for step: Int) -> some View {
        let isSelected = selection == step

        return Button {
            selection = isSelected ? nil : step
        } label: {
            Text("\(step)")
                .font(.body.weight(isSelected ? .semibold : .regular))
                .frame(maxWidth: .infinity)
                .aspectRatio(1, contentMode: .fit)
                .foregroundStyle(isSelected ? accent.onAccentColor(in: theme) : theme.muted)
                .background {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(isSelected ? accent.accentColor(in: theme) : theme.surface)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .strokeBorder(
                            isSelected ? accent.accentColor(in: theme) : theme.line,
                            lineWidth: 1
                        )
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel(for: step, isSelected: isSelected))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
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
    .background(Theme.plumEmber.base)
    .environment(\.theme, .plumEmber)
}
