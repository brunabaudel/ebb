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
    /// Alarm time (e.g. "9:00 AM") — warm tabular type at the bottom of the tile.
    var subtitle: String?
    /// Repeat preset (e.g. "Daily") — faint line below the time.
    var detail: String?
    /// Duration (e.g. "Ongoing") — faint line below frequency.
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

    private var reminderTitleFont: Font {
        .footnote.weight(isSelected ? .semibold : .regular)
    }

    private var reminderTitleColor: Color {
        isSelected ? theme.text : theme.muted
    }

    private var alarmNameFont: Font {
        .caption.weight(isSelected ? .semibold : .medium)
    }

    private var alarmNameColor: Color {
        isSelected ? theme.text : theme.muted
    }

    private var alarmTimeColor: Color {
        theme.warmInk
    }

    private var alarmMetaColor: Color {
        theme.muted
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
        let hasAlarm = subtitle != nil

        Group {
            if hasAlarm {
                alarmTileInterior
            } else {
                defaultTileInterior
            }
        }
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

    private var defaultTileInterior: some View {
        VStack(spacing: 1) {
            Text(title)
                .font(reminderTitleFont)
                .foregroundStyle(reminderTitleColor)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .padding(.horizontal, 6)
    }

    private var alarmTileInterior: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(alarmNameFont)
                .foregroundStyle(alarmNameColor)
                .multilineTextAlignment(.leading)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 4)

            VStack(alignment: .leading, spacing: 2) {
                if let subtitle {
                    Text(subtitle)
                        .font(.caption.weight(.medium))
                        .monospacedDigit()
                        .foregroundStyle(alarmTimeColor)
                        .lineLimit(1)
                }

                if let detail {
                    Text(detail)
                        .font(.caption2)
                        .foregroundStyle(alarmMetaColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }

                if let footnote {
                    Text(footnote)
                        .font(.caption2)
                        .foregroundStyle(alarmMetaColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.top, 14)
        .padding(.horizontal, 13)
        .padding(.bottom, 12)
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

#Preview("Relief alarm tile") {
    HStack(spacing: 10) {
        CareSelectionTile(
            title: "Ibuprofen",
            subtitle: "9:00",
            detail: "Daily",
            footnote: "Ongoing",
            isSelected: true,
            onLongPress: {}
        ) {}
        CareSelectionTile(
            title: "Triptan",
            subtitle: "21:00",
            detail: "Mon Wed Fri",
            footnote: "Until Sep 30",
            isSelected: false,
            onLongPress: {}
        ) {}
    }
    .padding()
    .background(Theme.softPaper.base)
    .environment(\.theme, .softPaper)
}

#Preview("Reminder landscape tile") {
    CareSelectionTile(
        title: "Daily log reminder",
        isSelected: true,
        shape: .landscape()
    ) {}
    .padding()
    .background(Theme.softPaper.base)
    .environment(\.theme, .softPaper)
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
