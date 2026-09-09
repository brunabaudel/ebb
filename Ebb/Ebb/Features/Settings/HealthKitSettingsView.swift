import SwiftUI

struct HealthKitSettingsView: View {
    @Environment(\.theme) private var theme
    @Environment(\.openURL) private var openURL
    @Environment(CycleService.self) private var cycleService
    @Environment(AppLockController.self) private var appLock
    @State private var isRequestingHealthKit = false

    var body: some View {
        List {
            Section {
                healthKitConnectionRow

                Text(healthKitExplanation)
                    .font(.footnote)
                    .foregroundStyle(theme.muted)
                    .themeListRow()

                healthKitActions
            } header: {
                Text("HealthKit")
            }
        }
        .themeSettingsList()
        .navigationTitle("HealthKit")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await cycleService.refresh()
        }
        .onDisappear {
            appLock.endPermissionFlow()
        }
    }

    @ViewBuilder
    private var healthKitConnectionRow: some View {
        switch cycleService.authorizationStatus {
        case .authorized, .unavailable:
            healthKitConnectionLabel
                .themeListRow()

        case .notDetermined, .denied:
            Button {
                Task { await connectHealthKit() }
            } label: {
                healthKitConnectionLabel
            }
            .disabled(isRequestingHealthKit)
            .themeListRow()
        }
    }

    private var healthKitConnectionLabel: some View {
        LabeledContent {
            Text(healthKitStatusLabel)
                .foregroundStyle(healthKitStatusColor)
        } label: {
            Label("Connection", systemImage: "heart.text.square")
        }
    }

    @ViewBuilder
    private var healthKitActions: some View {
        switch cycleService.authorizationStatus {
        case .notDetermined:
            if isRequestingHealthKit {
                ProgressView()
                    .themeListRow()
            }

        case .authorized:
            Button("Refresh cycle data") {
                Task { await cycleService.refresh() }
            }
            .themeListRow()
            if cycleService.healthKitPeriodDays.isEmpty {
                Text("No menstrual flow data found yet. In the Health app, open Sharing → Apps → Ebb and turn on Menstrual Cycle.")
                    .font(.footnote)
                    .foregroundStyle(theme.muted)
                    .themeListRow()
            }
            Button("Open Health app") {
                openHealthApp()
            }
            .themeListRow()

        case .denied:
            Text("Ebb cannot read menstrual data. Open the Health app → Sharing → Apps → Ebb and allow Menstrual Cycle.")
                .font(.footnote)
                .foregroundStyle(theme.muted)
                .themeListRow()
            Button("Open Health app") {
                openHealthApp()
            }
            .themeListRow()

        case .unavailable:
            Text("HealthKit is not available on this device.")
                .font(.footnote)
                .foregroundStyle(theme.muted)
                .themeListRow()
        }
    }

    private var healthKitExplanation: String {
        "Ebb reads menstrual flow from HealthKit to tag your cycle phase and predict your next period. Nothing is written to HealthKit."
    }

    private var healthKitStatusLabel: String {
        switch cycleService.authorizationStatus {
        case .unavailable: "Unavailable"
        case .notDetermined: "Not connected — tap to connect"
        case .authorized:
            cycleService.healthKitPeriodDays.isEmpty ? "Connected (no data yet)" : "Connected"
        case .denied: "Needs permission — tap to try again"
        }
    }

    private var healthKitStatusColor: Color {
        switch cycleService.authorizationStatus {
        case .authorized: theme.ok
        case .denied: theme.pain
        default: theme.muted
        }
    }

    private func connectHealthKit() async {
        isRequestingHealthKit = true
        appLock.beginHealthKitAuthorizationFlow()
        defer {
            isRequestingHealthKit = false
            appLock.endPermissionFlow()
        }
        await cycleService.requestAuthorization()
    }

    private func openHealthApp() {
        guard let url = URL(string: "x-apple-health://") else { return }
        appLock.beginExternalHealthAppFlow()
        openURL(url)
    }
}

#Preview {
    NavigationStack {
        HealthKitSettingsView()
    }
    .environment(\.theme, .softPaper)
    .environment(CycleService(provider: MockCycleDataProvider.lutealSample()))
    .environment(AppLockController())
}
