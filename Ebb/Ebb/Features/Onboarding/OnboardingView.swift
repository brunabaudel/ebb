import SwiftUI

/// First-run flow: disclaimer, cycle info, and HealthKit (Phase 9).
struct OnboardingView: View {
    @Bindable var viewModel: OnboardingViewModel
    @Bindable var onboardingPreferences: OnboardingPreferences

    @Environment(\.theme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(CycleService.self) private var cycleService
    @Environment(AppLockController.self) private var appLock

    @State private var primaryHapticTrigger = 0
    @State private var secondaryHapticTrigger = 0

    private var stepIndex: Int { viewModel.step.rawValue }
    private var totalSteps: Int { OnboardingViewModel.Step.allCases.count }
    private var progressFraction: Double {
        Double(stepIndex + 1) / Double(totalSteps)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if viewModel.step != .welcome {
                    stepProgressHeader
                        .padding(.horizontal, 24)
                        .padding(.top, 12)
                        .padding(.bottom, 4)
                }

                Group {
                    switch viewModel.step {
                    case .welcome:
                        welcomeContent
                    case .cycleInfo:
                        cycleInfoContent
                    case .healthKit:
                        healthKitContent
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .id(viewModel.step)
                .transition(reduceMotion ? .identity : .opacity)

                stickyFooter
            }
            .background(theme.base)
            .foregroundStyle(theme.text)
            .navigationBarTitleDisplayMode(.inline)
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.28), value: viewModel.step)
        }
        .interactiveDismissDisabled()
    }

    // MARK: - Welcome

    private var welcomeContent: some View {
        ScrollView {
            VStack(spacing: 28) {
                EbbIllustrationWell(variant: .happy, diameter: 120, mascotSize: 96)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)

                VStack(alignment: .leading, spacing: 10) {
                    Text("A calmer way to track migraines and your cycle.")
                        .font(.system(.title2, design: .serif))
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Everything stays on your phone. On-device migraine and cycle tracking — talk or tap, your choice every time.")
                        .font(.subheadline)
                        .foregroundStyle(theme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text(MedicalDisclaimer.shortLine)
                    .font(.footnote)
                    .foregroundStyle(theme.faint)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityLabel("Medical disclaimer. \(MedicalDisclaimer.shortLine)")
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 16)
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Cycle info

    private var cycleInfoContent: some View {
        @Bindable var preferences = cycleService.preferences

        return ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                stepHeader(
                    title: "Your cycle",
                    subtitle: "Optional — helps when HealthKit has no recent flow data."
                )

                Stepper(
                    value: $preferences.typicalCycleLength,
                    in: CyclePreferences.cycleLengthRange,
                    step: 1
                ) {
                    LabeledContent("Typical cycle length") {
                        Text("\(preferences.typicalCycleLength) days")
                    }
                }
                .themeCard(padding: 16)
                .accessibilityLabel("Typical cycle length, \(preferences.typicalCycleLength) days")

                Toggle(isOn: $preferences.hasAura) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("I get migraine aura")
                        Text("Visual or sensory warning before a migraine. Recorded for your doctor export — Ebb never gives medical advice.")
                            .font(.caption)
                            .foregroundStyle(theme.muted)
                    }
                }
                .themeCard(padding: 16)
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 16)
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - HealthKit

    private var healthKitContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                EbbIllustrationWell(variant: .listen, diameter: 88, mascotSize: 64)
                    .frame(maxWidth: .infinity)
                    .accessibilityHidden(true)

                stepHeader(
                    title: "Connect Apple Health",
                    subtitle: "Ebb reads menstrual flow to tag your cycle phase and predict your next period. Nothing is written to HealthKit."
                )

                HStack(alignment: .top, spacing: 14) {
                    Image(systemName: "heart.text.square.fill")
                        .font(.title3)
                        .foregroundStyle(theme.cycle)
                        .frame(width: 28)
                        .accessibilityHidden(true)

                    Text("Read-only access to menstrual flow. Your migraine logs never leave your phone.")
                        .font(.footnote)
                        .foregroundStyle(theme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .themeCard(padding: 16)
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 16)
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Progress

    private var stepProgressHeader: some View {
        HStack(spacing: 12) {
            HStack(spacing: 6) {
                ForEach(0..<totalSteps, id: \.self) { index in
                    Circle()
                        .fill(index <= stepIndex ? theme.pain : theme.line)
                        .frame(width: 6, height: 6)
                }
            }
            .accessibilityHidden(true)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(theme.line)
                        .frame(height: 3)
                    Capsule()
                        .fill(theme.pain)
                        .frame(width: geometry.size.width * progressFraction, height: 3)
                }
            }
            .frame(height: 3)

            Text("\(stepIndex + 1) of \(totalSteps)")
                .font(.system(size: 10, design: .monospaced))
                .kerning(0.4)
                .foregroundStyle(theme.faint)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Step \(stepIndex + 1) of \(totalSteps)")
    }

    // MARK: - Sticky footer

    @ViewBuilder
    private var stickyFooter: some View {
        VStack(spacing: 0) {
            Divider().overlay(theme.line)

            VStack(spacing: 12) {
                switch viewModel.step {
                case .welcome:
                    primaryButton("Get started") {
                        viewModel.advance(from: onboardingPreferences)
                    }

                case .cycleInfo:
                    primaryButton("Continue") {
                        viewModel.advance(from: onboardingPreferences)
                    }
                    secondaryButton("Skip") {
                        viewModel.advance(from: onboardingPreferences)
                    }

                case .healthKit:
                    primaryButton(viewModel.isRequestingPermission ? "Connecting…" : "Connect Health") {
                        Task {
                            await viewModel.requestHealthKit(cycleService: cycleService, appLock: appLock)
                            viewModel.advance(from: onboardingPreferences)
                        }
                    }
                    .disabled(viewModel.isRequestingPermission)

                    secondaryButton("Not now") {
                        viewModel.advance(from: onboardingPreferences)
                    }
                    .disabled(viewModel.isRequestingPermission)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
        .background(theme.base)
    }

    // MARK: - Shared pieces

    private func stepHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(.title2, design: .serif))
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(theme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func primaryButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button {
            primaryHapticTrigger += 1
            action()
        } label: {
            Text(title)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(theme.pain)
        .sensoryFeedback(.selection, trigger: primaryHapticTrigger)
    }

    private func secondaryButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button {
            secondaryHapticTrigger += 1
            action()
        } label: {
            Text(title)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .tint(theme.muted)
        .sensoryFeedback(.selection, trigger: secondaryHapticTrigger)
    }
}

#Preview {
    OnboardingView(
        viewModel: OnboardingViewModel(),
        onboardingPreferences: OnboardingPreferences()
    )
    .background(Theme.softPaper.base)
    .environment(\.theme, .softPaper)
    .environment(CycleService(provider: MockCycleDataProvider()))
    .environment(AppLockController())
}
