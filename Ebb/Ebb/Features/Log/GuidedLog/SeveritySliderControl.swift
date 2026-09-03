import SwiftUI

/// Continuous severity control for the guided flow (mockup K).
struct SeveritySliderControl: View {
    let range: ClosedRange<Int>
    let labels: [Int: String]
    @Binding var selection: Int?
    let accent: FieldAccent

    @Environment(\.theme) private var theme

    private var sliderValue: Double {
        Double(selection ?? range.lowerBound)
    }

    var body: some View {
        VStack(spacing: 8) {
            Text("\(selection ?? range.lowerBound)")
                .font(.system(size: 48, weight: .medium, design: .serif))
                .foregroundStyle(accent.accentColor(in: theme))

            if let selection, let caption = labels[selection] {
                Text(caption)
                    .font(.subheadline)
                    .foregroundStyle(theme.muted)
                    .italic()
            }

            Slider(
                value: Binding(
                    get: { sliderValue },
                    set: { selection = Int($0.rounded()) }
                ),
                in: Double(range.lowerBound)...Double(range.upperBound),
                step: 1
            )
            .tint(accent.accentColor(in: theme))

            HStack {
                Text(labels[range.lowerBound] ?? "min")
                Spacer()
                Text(labels[range.upperBound] ?? "max")
            }
            .font(.caption2)
            .foregroundStyle(theme.muted)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Severity")
        .accessibilityValue(accessibilityValue)
    }

    private var accessibilityValue: String {
        guard let selection else { return "Not set" }
        let caption = labels[selection].map { ", \($0)" } ?? ""
        return "Level \(selection) of \(range.upperBound)\(caption)"
    }
}

#Preview {
    @Previewable @State var severity: Int? = 3
    SeveritySliderControl(
        range: 1...5,
        labels: [1: "barely there", 3: "moderate", 5: "disabling"],
        selection: $severity,
        accent: .pain
    )
    .padding()
    .background(Theme.plumEmber.base)
    .environment(\.theme, .plumEmber)
}
