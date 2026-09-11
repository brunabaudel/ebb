import SwiftUI

/// Soft paper 01.2 visual chrome — float cards, gentler shadows, rounder chips.
/// Applied when the active theme opts into light “paper” styling (`Theme.isLight`).
extension Theme {
    var isLight: Bool {
        id == Self.softPaper.id || id == Self.oatRose.id
    }

    var cardCornerRadius: CGFloat {
        isLight ? 20 : 16
    }

    var chipVerticalPadding: CGFloat {
        isLight ? 8 : 7
    }

    var chipHorizontalPadding: CGFloat {
        isLight ? 13 : 12
    }

    var cardShadowColor: Color {
        isLight ? Color.black.opacity(0.08) : .clear
    }

    var cardShadowRadius: CGFloat {
        isLight ? 14 : 0
    }

    var cardShadowY: CGFloat {
        isLight ? 6 : 0
    }

    var fabShadowOpacity: Double {
        isLight ? 0.35 : 0.45
    }
}

extension View {
    /// Elevated surface card using semantic theme tokens.
    func themeCard(
        padding: CGFloat = 0,
        cornerRadius: CGFloat? = nil
    ) -> some View {
        modifier(ThemeCardModifier(padding: padding, cornerRadius: cornerRadius))
    }

    /// Settings hub and pushed subpages — base fill, nav bar, and color scheme aligned to the active theme.
    func themeSettingsScreen() -> some View {
        modifier(ThemeSettingsScreenModifier())
    }

    /// Settings `List` — hides the system scroll background; pair with `themeListRow()` on rows.
    func themeSettingsList() -> some View {
        scrollContentBackground(.hidden)
            .themeSettingsScreen()
    }

    /// Surface fill for one Settings list row (`theme.surface`, separator tint).
    func themeListRow() -> some View {
        modifier(ThemeListRowModifier())
    }
}

private struct ThemeSettingsScreenModifier: ViewModifier {
    @Environment(\.theme) private var theme

    func body(content: Content) -> some View {
        content
            .background(theme.base)
            .foregroundStyle(theme.text)
            .toolbarBackground(theme.base, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
    }
}

private struct ThemeListRowModifier: ViewModifier {
    @Environment(\.theme) private var theme

    func body(content: Content) -> some View {
        content
            .listRowBackground(theme.surface)
            .listRowSeparatorTint(theme.line)
    }
}

private struct ThemeCardModifier: ViewModifier {
    @Environment(\.theme) private var theme

    let padding: CGFloat
    let cornerRadius: CGFloat?

    func body(content: Content) -> some View {
        let radius = cornerRadius ?? theme.cardCornerRadius

        content
            .padding(padding)
            .background(theme.surface, in: RoundedRectangle(cornerRadius: radius))
            .overlay {
                RoundedRectangle(cornerRadius: radius)
                    .strokeBorder(theme.line, lineWidth: 1)
            }
            .shadow(
                color: theme.cardShadowColor,
                radius: theme.cardShadowRadius,
                y: theme.cardShadowY
            )
    }
}
