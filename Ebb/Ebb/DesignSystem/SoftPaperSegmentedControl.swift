import SwiftUI

/// Custom segmented control with a taller tap target and Soft paper styling.
/// Replaces `Picker(.segmented)`, which ignores explicit height and stays ~32pt.
struct SoftPaperSegmentedControl<Selection: Hashable>: View {
    struct Segment: Identifiable {
        let id: Selection
        let title: String
    }

    let segments: [Segment]
    @Binding var selection: Selection

    @Environment(\.theme) private var theme

    private static let innerHeight: CGFloat = 50
    private static let trackInset: CGFloat = 4

    var body: some View {
        HStack(spacing: 4) {
            ForEach(segments) { segment in
                segmentButton(segment)
            }
        }
        .padding(Self.trackInset)
        .frame(maxWidth: .infinity)
        .background(
            theme.surface,
            in: RoundedRectangle(cornerRadius: theme.cardCornerRadius, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: theme.cardCornerRadius, style: .continuous)
                .strokeBorder(theme.line, lineWidth: 1)
        }
        .accessibilityElement(children: .contain)
    }

    private var innerCornerRadius: CGFloat {
        max(theme.cardCornerRadius - 6, 12)
    }

    private func segmentButton(_ segment: Segment) -> some View {
        let isSelected = selection == segment.id

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selection = segment.id
            }
        } label: {
            Text(segment.title)
                .font(.subheadline.weight(isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? theme.text : theme.muted)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .frame(maxWidth: .infinity)
                .frame(height: Self.innerHeight)
                .background {
                    if isSelected {
                        selectedSegmentBackground
                    }
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(segment.title)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    private var selectedSegmentBackground: some View {
        RoundedRectangle(cornerRadius: innerCornerRadius, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [theme.pain.opacity(0.22), theme.pain.opacity(0.28)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay {
                RoundedRectangle(cornerRadius: innerCornerRadius, style: .continuous)
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
            .init(id: 1, title: "Medications"),
            .init(id: 2, title: "Reminders"),
            .init(id: 3, title: "Cycle"),
        ],
        selection: $selection
    )
    .padding()
    .background(Theme.softPaper.base)
    .environment(\.theme, .softPaper)
}
