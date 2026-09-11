import SwiftUI

private enum SoftPaperSegmentedControlMetrics {
    static let innerHeight: CGFloat = 50
    static let trackInset: CGFloat = 4
    static let segmentSpacing: CGFloat = 4
    static let selectedRoseTintOpacity: Double = 0.34
    static let trackOatTintOpacity: Double = 0.55

    static var trackHeight: CGFloat { innerHeight + trackInset * 2 }
    static var trackCornerRadius: CGFloat { trackHeight / 2 }
    static var selectedCornerRadius: CGFloat { innerHeight / 2 }
}

/// Custom segmented control with a taller tap target and Soft paper styling.
/// Replaces `Picker(.segmented)`, which ignores explicit height and stays ~32pt.
///
/// On iOS 26+, the track and selected pill use SwiftUI Liquid Glass (`glassEffect`).
/// Earlier OS versions keep the opaque Soft paper capsule fallback.
struct SoftPaperSegmentedControl<Selection: Hashable>: View {
    struct Segment: Identifiable {
        let id: Selection
        let title: String
    }

    let segments: [Segment]
    @Binding var selection: Selection

    @Environment(\.theme) private var theme
    @Namespace private var glassNamespace

    var body: some View {
        if #available(iOS 26.0, *) {
            liquidGlassBody
        } else {
            softPaperFallbackBody
        }
    }

    // MARK: - iOS 26+ Liquid Glass

    @available(iOS 26.0, *)
    private var liquidGlassBody: some View {
        GlassEffectContainer(spacing: SoftPaperSegmentedControlMetrics.trackInset) {
            HStack(spacing: SoftPaperSegmentedControlMetrics.segmentSpacing) {
                ForEach(segments) { segment in
                    liquidGlassSegmentButton(segment)
                }
            }
            .padding(SoftPaperSegmentedControlMetrics.trackInset)
            .frame(maxWidth: .infinity)
            .glassEffect(
                .regular.tint(theme.surface.opacity(SoftPaperSegmentedControlMetrics.trackOatTintOpacity)),
                in: Capsule(style: .continuous)
            )
        }
        .accessibilityElement(children: .contain)
    }

    @available(iOS 26.0, *)
    private func liquidGlassSegmentButton(_ segment: Segment) -> some View {
        let isSelected = selection == segment.id

        return Button {
            withAnimation(.smooth(duration: 0.35)) {
                selection = segment.id
            }
        } label: {
            liquidGlassSegmentLabel(isSelected: isSelected, title: segment.title)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(segment.title)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    @available(iOS 26.0, *)
    @ViewBuilder
    private func liquidGlassSegmentLabel(isSelected: Bool, title: String) -> some View {
        let label = segmentLabel(isSelected: isSelected, title: title)

        if isSelected {
            label
                .glassEffect(
                    .regular
                        .tint(theme.pain.opacity(SoftPaperSegmentedControlMetrics.selectedRoseTintOpacity))
                        .interactive(),
                    in: Capsule(style: .continuous)
                )
                .glassEffectID("selected", in: glassNamespace)
        } else {
            label
        }
    }

    // MARK: - iOS 17–25 Soft paper fallback

    private var softPaperFallbackBody: some View {
        HStack(spacing: SoftPaperSegmentedControlMetrics.segmentSpacing) {
            ForEach(segments) { segment in
                softPaperSegmentButton(segment)
            }
        }
        .padding(SoftPaperSegmentedControlMetrics.trackInset)
        .frame(maxWidth: .infinity)
        .background {
            Capsule(style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    Capsule(style: .continuous)
                        .fill(theme.surface.opacity(0.72))
                }
        }
        .overlay {
            Capsule(style: .continuous)
                .strokeBorder(theme.line, lineWidth: 1)
        }
        .accessibilityElement(children: .contain)
    }

    private func softPaperSegmentButton(_ segment: Segment) -> some View {
        let isSelected = selection == segment.id

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selection = segment.id
            }
        } label: {
            segmentLabel(isSelected: isSelected, title: segment.title)
                .background {
                    if isSelected {
                        softPaperSelectedSegmentBackground
                    }
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(segment.title)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    private func segmentLabel(isSelected: Bool, title: String) -> some View {
        Text(title)
            .font(.subheadline.weight(isSelected ? .semibold : .regular))
            .foregroundStyle(isSelected ? theme.text : theme.muted)
            .lineLimit(1)
            .minimumScaleFactor(0.85)
            .frame(maxWidth: .infinity)
            .frame(height: SoftPaperSegmentedControlMetrics.innerHeight)
            .contentShape(Capsule(style: .continuous))
    }

    private var softPaperSelectedSegmentBackground: some View {
        Capsule(style: .continuous)
            .fill(
                LinearGradient(
                    colors: [theme.pain.opacity(0.22), theme.pain.opacity(0.28)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay {
                Capsule(style: .continuous)
                    .inset(by: 0.5)
                    .stroke(
                        LinearGradient(
                            colors: [theme.surface.opacity(0.45), theme.surface.opacity(0)],
                            startPoint: .top,
                            endPoint: .center
                        ),
                        lineWidth: 1
                    )
            }
            .shadow(color: theme.pain.opacity(0.18), radius: 8, y: 2)
            .shadow(color: theme.pain.opacity(0.08), radius: 2, y: 1)
    }
}

#Preview {
    @Previewable @State var selection = 0

    SoftPaperSegmentedControl(
        segments: [
            .init(id: 0, title: "Doctor"),
            .init(id: 1, title: "Relief"),
            .init(id: 2, title: "Reminders"),
            .init(id: 3, title: "Cycle"),
        ],
        selection: $selection
    )
    .padding()
    .background(Theme.softPaper.base)
    .environment(\.theme, .softPaper)
}
