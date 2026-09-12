import SwiftUI

/// Cycle length, period length, and aura settings shared by My care and onboarding-style layouts.
struct CycleInfoControls: View {
    @Bindable var preferences: CyclePreferences

    @Environment(\.theme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            CareTileGrid(columnCount: 2) {
                CareCycleLengthTile(
                    title: "Cycle",
                    accessibilityName: "Typical cycle length",
                    value: $preferences.typicalCycleLength,
                    range: CyclePreferences.cycleLengthRange
                )

                CareCycleLengthTile(
                    title: "Period",
                    accessibilityName: "Typical period length",
                    value: $preferences.periodLength,
                    range: CyclePreferences.periodLengthRange
                )
            }

            Text("Used when HealthKit has no recent flow data, and to predict your next period.")
                .font(.footnote)
                .foregroundStyle(theme.muted)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 4)

            Toggle(isOn: $preferences.hasAura) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("I get migraine aura")
                    Text("Visual or sensory warning. Doctor export only.")
                        .font(.caption)
                        .foregroundStyle(theme.muted)
                }
            }
            .tint(theme.ok)
            .themeCard(padding: 16, cornerRadius: theme.cardCornerRadius)
        }
    }
}

private enum CycleLengthTileLayout {
    static let height: CGFloat = 85
}

private struct CareCycleLengthTile: View {
    let title: String
    let accessibilityName: String
    @Binding var value: Int
    let range: ClosedRange<Int>

    @Environment(\.theme) private var theme

    var body: some View {
        let cornerRadius = max(CareTileLayout.cornerRadius, theme.cardCornerRadius)

        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.body)
                .foregroundStyle(theme.text)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 4)

            HStack(alignment: .center, spacing: 8) {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("\(value)")
                        .font(.title2.weight(.medium))
                        .monospacedDigit()
                        .foregroundStyle(theme.warmInk)

                    Text("d")
                        .font(.caption)
                        .foregroundStyle(theme.muted)
                }

                Spacer(minLength: 0)

                compactStepper
            }
        }
        .padding(.top, 14)
        .padding(.horizontal, 13)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity)
        .frame(height: CycleLengthTileLayout.height)
        .background {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(theme.surface)
        }
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(theme.line, lineWidth: 1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(accessibilityName), \(value) days")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment:
                increment()
            case .decrement:
                decrement()
            @unknown default:
                break
            }
        }
        .accessibilityAction(named: "Increment") {
            increment()
        }
        .accessibilityAction(named: "Decrement") {
            decrement()
        }
    }

    private var compactStepper: some View {
        HStack(spacing: 0) {
            stepperButton(systemName: "minus", isEnabled: value > range.lowerBound) {
                decrement()
            }

            stepperButton(systemName: "plus", isEnabled: value < range.upperBound) {
                increment()
            }
        }
        .accessibilityHidden(true)
    }

    private func stepperButton(
        systemName: String,
        isEnabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.caption.weight(.semibold))
                .frame(width: 28, height: 28)
                .foregroundStyle(isEnabled ? theme.text : theme.muted.opacity(0.45))
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }

    private func increment() {
        guard value < range.upperBound else { return }
        value += 1
    }

    private func decrement() {
        guard value > range.lowerBound else { return }
        value -= 1
    }
}

#Preview {
    CycleInfoControls(preferences: CyclePreferences())
        .padding()
        .background(Theme.softPaper.base)
        .environment(\.theme, .softPaper)
}
