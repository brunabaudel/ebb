import SwiftUI

enum CareTileLayout {
    static let size: CGFloat = 104
    static let gutter: CGFloat = 10
    static let cornerRadius: CGFloat = 24
    static let columnCount = 2
    static let reminderHeight: CGFloat = 70

    static func columnWidth(forContentWidth contentWidth: CGFloat, columnCount: Int = columnCount) -> CGFloat {
        let gutter = CareTileLayout.gutter
        guard contentWidth > 0, columnCount > 0 else {
            return size
        }
        return floor((contentWidth - CGFloat(columnCount - 1) * gutter) / CGFloat(columnCount))
    }
}

struct CareSelectionTile: View {
    let title: String
    let isSelected: Bool
    var tileSize: CGFloat = CareTileLayout.size
    var tileWidth: CGFloat?
    var tileHeight: CGFloat?
    var action: () -> Void

    private var resolvedWidth: CGFloat { tileWidth ?? tileSize }
    private var resolvedHeight: CGFloat { tileHeight ?? tileSize }

    @Environment(\.theme) private var theme

    var body: some View {
        let cornerRadius = max(CareTileLayout.cornerRadius, theme.cardCornerRadius)

        Button(action: action) {
            Text(title)
                .font(.footnote.weight(isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? theme.text : theme.muted)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
                .padding(.horizontal, 8)
                .frame(width: resolvedWidth, height: resolvedHeight)
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
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityValue(isSelected ? "On" : "Off")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

struct CareTileGrid<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        Grid(
            horizontalSpacing: CareTileLayout.gutter,
            verticalSpacing: CareTileLayout.gutter
        ) {
            content()
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

#Preview("Square tile") {
    CareSelectionTile(title: "Ibuprofen", isSelected: true) {}
        .padding()
        .environment(\.theme, .softPaper)
}

#Preview("Landscape tile") {
    CareSelectionTile(
        title: "Luteal-window heads-up",
        isSelected: false,
        tileWidth: 160,
        tileHeight: CareTileLayout.reminderHeight
    ) {}
    .padding()
    .environment(\.theme, .softPaper)
}
