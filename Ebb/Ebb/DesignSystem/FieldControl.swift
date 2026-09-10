import SwiftUI

/// Renders any schema field as the correct control type. Adding a value to
/// `symptom-schema.json` makes a new pill appear here with zero Swift changes.
struct FieldControl: View {
    let field: SchemaField
    @Binding var value: FieldValue?
    var highlightedValues: Set<String> = []
    var accent: FieldAccent?

    @Environment(\.theme) private var theme

    private var resolvedAccent: FieldAccent {
        accent ?? field.accent
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(field.label.uppercased())
                .font(.caption2.weight(.semibold))
                .kerning(1.2)
                .foregroundStyle(theme.muted)
                .accessibilityHidden(true)

            switch field.type {
            case .boolean:
                booleanControl
            case .scale:
                scaleControl
            case .singleEnum:
                singleEnumControl
            case .multiEnum:
                multiEnumControl
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(field.label)
    }

    // MARK: - Boolean

    private var booleanControl: some View {
        HStack(spacing: 7) {
            SelectablePill(
                label: "Yes",
                isSelected: value == .boolean(true),
                isHighlighted: highlightedValues.contains("true"),
                accent: resolvedAccent
            ) {
                value = value == .boolean(true) ? nil : .boolean(true)
            }
            SelectablePill(
                label: "No",
                isSelected: value == .boolean(false),
                isHighlighted: highlightedValues.contains("false"),
                accent: resolvedAccent
            ) {
                value = value == .boolean(false) ? nil : .boolean(false)
            }
        }
    }

    // MARK: - Scale

    @ViewBuilder
    private var scaleControl: some View {
        if let range = field.range {
            ScaleStepper(
                range: range,
                labels: field.scaleLabels,
                selection: scaleBinding,
                isHighlighted: !highlightedValues.isEmpty,
                accent: resolvedAccent
            )
        }
    }

    private var scaleBinding: Binding<Int?> {
        Binding(
            get: {
                if case .scale(let step)? = value { return step }
                return nil
            },
            set: { newValue in
                value = newValue.map { .scale($0) }
            }
        )
    }

    // MARK: - Single enum

    private var singleEnumControl: some View {
        FlowLayout(spacing: 7) {
            ForEach(field.values) { option in
                SelectablePill(
                    label: option.label,
                    isSelected: value == .choice(option.key),
                    isHighlighted: highlightedValues.contains(option.key),
                    accent: resolvedAccent
                ) {
                    value = value == .choice(option.key) ? nil : .choice(option.key)
                }
            }
        }
    }

    // MARK: - Multi enum

    private var multiEnumControl: some View {
        FlowLayout(spacing: 7) {
            ForEach(field.values) { option in
                SelectablePill(
                    label: option.label,
                    isSelected: selectedChoices.contains(option.key),
                    isHighlighted: highlightedValues.contains(option.key),
                    accent: resolvedAccent
                ) {
                    toggleChoice(option.key)
                }
            }
        }
    }

    private var selectedChoices: Set<String> {
        Set(orderedChoices)
    }

    private var orderedChoices: [String] {
        if case .choices(let keys)? = value { return keys }
        return []
    }

    private func toggleChoice(_ key: String) {
        var choices = orderedChoices
        if let index = choices.firstIndex(of: key) {
            choices.remove(at: index)
        } else {
            choices.append(key)
        }
        value = choices.isEmpty ? nil : .choices(choices)
    }
}

// MARK: - Flow layout for pills

/// Wraps pill controls onto multiple lines without hard-coding field widths.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    var centerRows: Bool = false
    /// When set, both sizing and placement use this width so text can wrap even if
    /// the layout proposal width is unspecified.
    var arrangementWidth: CGFloat? = nil

    struct Cache {
        var lastBoundsWidth: CGFloat = 0
    }

    func makeCache(subviews: Subviews) -> Cache {
        Cache()
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Cache) -> CGSize {
        let maxWidth = effectiveMaxWidth(proposal: proposal, boundsWidth: nil, cache: cache)
        let result = arrange(maxWidth: maxWidth, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Cache) {
        if bounds.width > 0 {
            cache.lastBoundsWidth = bounds.width
        }
        let maxWidth = effectiveMaxWidth(proposal: proposal, boundsWidth: bounds.width, cache: cache)
        let result = arrange(maxWidth: maxWidth, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            let size = result.sizes[index]
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: ProposedViewSize(width: size.width, height: nil)
            )
        }
    }

    private func effectiveMaxWidth(
        proposal: ProposedViewSize,
        boundsWidth: CGFloat?,
        cache: Cache
    ) -> CGFloat {
        if let arrangementWidth, arrangementWidth > 0 {
            return arrangementWidth
        }
        if let width = proposal.width {
            return width
        }
        if let width = boundsWidth, width > 0 {
            return width
        }
        if cache.lastBoundsWidth > 0 {
            return cache.lastBoundsWidth
        }
        return .infinity
    }

    private func arrange(maxWidth: CGFloat, subviews: Subviews) -> Arrangement {
        var positions: [CGPoint] = []
        var sizes: [CGSize] = []
        var rowRanges: [Range<Int>] = []
        var rowStart = 0
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        var contentWidth: CGFloat = 0

        for subview in subviews {
            let remainingWidth = maxWidth.isFinite ? max(maxWidth - x, 0) : .infinity
            var size = measuredSize(for: subview, maxWidth: remainingWidth)

            if maxWidth.isFinite, x + size.width > maxWidth, x > 0 {
                rowRanges.append(rowStart..<positions.count)
                rowStart = positions.count
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
                size = measuredSize(for: subview, maxWidth: maxWidth)
            }

            positions.append(CGPoint(x: x, y: y))
            sizes.append(size)
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            contentWidth = max(contentWidth, x - spacing)
            totalHeight = y + rowHeight
        }
        if rowStart < positions.count {
            rowRanges.append(rowStart..<positions.count)
        }

        if centerRows, maxWidth.isFinite {
            for range in rowRanges {
                var rowWidth: CGFloat = 0
                for index in range {
                    rowWidth = max(rowWidth, positions[index].x + sizes[index].width)
                }
                let offset = max((maxWidth - rowWidth) / 2, 0)
                for index in range {
                    positions[index].x += offset
                }
            }
        }

        return Arrangement(
            size: CGSize(width: maxWidth.isFinite ? maxWidth : contentWidth, height: totalHeight),
            positions: positions,
            sizes: sizes
        )
    }

    private func measuredSize(for subview: LayoutSubviews.Element, maxWidth: CGFloat) -> CGSize {
        let ideal = subview.sizeThatFits(.unspecified)
        guard maxWidth.isFinite, ideal.width > maxWidth else {
            return ideal
        }
        return subview.sizeThatFits(ProposedViewSize(width: maxWidth, height: nil))
    }

    private struct Arrangement {
        let size: CGSize
        let positions: [CGPoint]
        let sizes: [CGSize]
    }
}

private struct FlowLayoutContainerWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

/// Reads the container width and passes it into ``FlowLayout`` so multiline phrase
/// segments wrap during both measurement and placement.
struct FlowLayoutContainer<Content: View>: View {
    var spacing: CGFloat = 8
    var centerRows: Bool = false
    @ViewBuilder var content: () -> Content

    @State private var containerWidth: CGFloat = 0

    var body: some View {
        FlowLayout(
            spacing: spacing,
            centerRows: centerRows,
            arrangementWidth: containerWidth > 0 ? containerWidth : nil
        ) {
            content()
        }
        .frame(maxWidth: .infinity, alignment: centerRows ? .center : .leading)
        .background {
            GeometryReader { geometry in
                Color.clear
                    .preference(key: FlowLayoutContainerWidthKey.self, value: geometry.size.width)
            }
        }
        .onPreferenceChange(FlowLayoutContainerWidthKey.self) { newWidth in
            guard newWidth > 0, abs(newWidth - containerWidth) > 0.5 else { return }
            containerWidth = newWidth
        }
    }
}

#Preview {
    @Previewable @State var values: [String: FieldValue] = [:]
    let schema = try! SchemaConfig.load()

    ScrollView {
        VStack(alignment: .leading, spacing: 20) {
            ForEach(schema.fields) { field in
                FieldControl(
                    field: field,
                    value: Binding(
                        get: { values[field.key] },
                        set: { values[field.key] = $0 }
                    )
                )
            }
        }
        .padding()
    }
    .background(Theme.plumEmber.base)
    .environment(\.theme, .plumEmber)
}
