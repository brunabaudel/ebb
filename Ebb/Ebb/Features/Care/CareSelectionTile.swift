import SwiftUI

enum CareTileLayout {
    static let size: CGFloat = 104
    static let gutter: CGFloat = 10
    static let cornerRadius: CGFloat = 24
    static let columnCount = 2
    static let reminderTileHeight: CGFloat = 70
}

struct CareSelectionTile: View {
    let title: String
    let isSelected: Bool
    var tileWidth: CGFloat = CareTileLayout.size
    var tileHeight: CGFloat = CareTileLayout.size
    var action: () -> Void

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
                .frame(width: tileWidth, height: tileHeight)
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
