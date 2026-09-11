import SwiftUI

/// Cycle length, period length, and aura settings shared by My care and onboarding-style layouts.
struct CycleInfoControls: View {
    @Bindable var preferences: CyclePreferences

    @Environment(\.theme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Stepper(
                value: $preferences.typicalCycleLength,
                in: CyclePreferences.cycleLengthRange,
                step: 1
            ) {
                LabeledContent("Typical cycle length") {
                    Text("\(preferences.typicalCycleLength) days")
                        .foregroundStyle(theme.muted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .themeCard(padding: 16, cornerRadius: theme.cardCornerRadius)
            .accessibilityLabel("Typical cycle length, \(preferences.typicalCycleLength) days")

            Stepper(
                value: $preferences.periodLength,
                in: CyclePreferences.periodLengthRange,
                step: 1
            ) {
                LabeledContent("Typical period length") {
                    Text("\(preferences.periodLength) days")
                        .foregroundStyle(theme.muted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .themeCard(padding: 16, cornerRadius: theme.cardCornerRadius)
            .accessibilityLabel("Typical period length, \(preferences.periodLength) days")

            Text("Used when HealthKit has no recent flow data, and to predict your next period.")
                .font(.footnote)
                .foregroundStyle(theme.muted)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 4)

            Toggle(isOn: $preferences.hasAura) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("I get migraine aura")
                    Text("Visual or sensory warning before a migraine. Recorded for your doctor export — Ebb never gives medical advice.")
                        .font(.caption)
                        .foregroundStyle(theme.muted)
                }
            }
            .tint(theme.ok)
            .themeCard(padding: 16, cornerRadius: theme.cardCornerRadius)
        }
    }
}

#Preview {
    CycleInfoControls(preferences: CyclePreferences())
        .padding()
        .background(Theme.softPaper.base)
        .environment(\.theme, .softPaper)
}
