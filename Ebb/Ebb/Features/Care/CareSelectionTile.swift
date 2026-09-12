import SwiftUI

enum CareTileLayout {
    static let size: CGFloat = 104
    static let gutter: CGFloat = 10
    static let cornerRadius: CGFloat = 24
    static let reminderTileHeight: CGFloat = 70
}

enum CareTileShape {
    case landscape(height: CGFloat = CareTileLayout.reminderTileHeight)
}

struct CareSelectionTile: View {
    let title: String
    var subtitle: String?
    /// Second alarm line (e.g. repeat preset) shown below `subtitle`.
    var detail: String?
    /// Third alarm line (e.g. ongoing or end date) shown below `detail`.
    var footnote: String?
    let isSelected: Bool
    var tileWidth: CGFloat = CareTileLayout.size
    var tileHeight: CGFloat = CareTileLayout.size
    var shape: CareTileShape?
    var onLongPress: (() -> Void)? = nil
    var action: () -> Void

    @Environment(\.theme) private var theme

    private var accessibilityLabel: String {
        var parts = [title]
        if let subtitle {
            parts.append("alarm \(subtitle)")
        }
        if let detail {
            parts.append(detail)
        }
        if let footnote {
            parts.append(footnote)
        }
        return parts.joined(separator: ", ")
    }

    private var alarmLineCount: Int {
        [subtitle, detail, footnote].compactMap { $0 }.count
    }

    var body: some View {
        let cornerRadius = max(CareTileLayout.cornerRadius, theme.cardCornerRadius)
        let tile = tileContent(cornerRadius: cornerRadius)

        Group {
            if let onLongPress {
                tile
                    .contentShape(RoundedRectangle(cornerRadius: cornerRadius))
                    .gesture(
                        LongPressGesture(minimumDuration: 0.5)
                            .onEnded { _ in onLongPress() }
                            .exclusively(before: TapGesture().onEnded { action() })
                    )
                    .accessibilityAction(named: "Alarm", onLongPress)
            } else {
                Button(action: action) {
                    tile
                }
                .buttonStyle(.plain)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(isSelected ? "On" : "Off")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    @ViewBuilder
    private func tileContent(cornerRadius: CGFloat) -> some View {
        let hasAlarmLines = alarmLineCount > 0
        let titleFont: Font = hasAlarmLines
            ? .caption.weight(isSelected ? .semibold : .regular)
            : .footnote.weight(isSelected ? .semibold : .regular)
        let titleLineLimit = alarmLineCount >= 3 ? 1 : 2

        VStack(spacing: 1) {
            Text(title)
                .font(titleFont)
                .foregroundStyle(isSelected ? theme.text : theme.muted)
                .multilineTextAlignment(.center)
                .lineLimit(titleLineLimit)
                .minimumScaleFactor(0.8)

            if let subtitle {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(isSelected ? theme.muted : theme.muted.opacity(0.85))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }

            if let detail {
                Text(detail)
                    .font(.caption2)
                    .foregroundStyle(isSelected ? theme.muted.opacity(0.9) : theme.muted.opacity(0.75))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }

            if let footnote {
                Text(footnote)
                    .font(.caption2)
                    .foregroundStyle(isSelected ? theme.muted.opacity(0.85) : theme.muted.opacity(0.7))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
        }
        .padding(.horizontal, 6)
        .modifier(CareTileFrameModifier(
            tileWidth: tileWidth,
            tileHeight: tileHeight,
            shape: shape
        ))
        .background {
            if isSelected {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [theme.pain.opacity(0.18), theme.pain.opacity(0.36)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            } else {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(theme.surface)
            }
        }
        .overlay {
            if isSelected {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .inset(by: 0.5)
                    .stroke(
                        LinearGradient(
                            colors: [theme.surface.opacity(0.45), theme.surface.opacity(0)],
                            startPoint: .top,
                            endPoint: .center
                        ),
                        lineWidth: 1
                    )
            } else {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(theme.line, lineWidth: 1)
            }
        }
        .shadow(color: isSelected ? theme.pain.opacity(0.32) : .clear, radius: 10, y: 3)
        .shadow(color: isSelected ? theme.pain.opacity(0.12) : .clear, radius: 2, y: 1)
    }
}

struct CareAddReliefTile: View {
    var tileWidth: CGFloat = CareTileLayout.size
    var tileHeight: CGFloat = CareTileLayout.size

    @Environment(\.theme) private var theme

    var body: some View {
        let cornerRadius = max(CareTileLayout.cornerRadius, theme.cardCornerRadius)

        Image(systemName: "plus")
            .font(.title3.weight(.semibold))
            .foregroundStyle(theme.muted)
            .frame(width: tileWidth, height: tileHeight)
            .background(theme.surface, in: RoundedRectangle(cornerRadius: cornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(theme.line, lineWidth: 1)
            }
            .accessibilityLabel("Add relief")
    }
}

struct CareTileGrid<Content: View>: View {
    let columnCount: Int
    @ViewBuilder var content: () -> Content

    var body: some View {
        LazyVGrid(
            columns: Array(
                repeating: GridItem(.flexible(), spacing: CareTileLayout.gutter),
                count: columnCount
            ),
            spacing: CareTileLayout.gutter
        ) {
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct CareTileFrameModifier: ViewModifier {
    let tileWidth: CGFloat
    let tileHeight: CGFloat
    let shape: CareTileShape?

    func body(content: Content) -> some View {
        switch shape {
        case .landscape(let height):
            content
                .frame(maxWidth: .infinity)
                .frame(height: height)
        case nil:
            content
                .frame(width: tileWidth, height: tileHeight)
        }
    }
}
