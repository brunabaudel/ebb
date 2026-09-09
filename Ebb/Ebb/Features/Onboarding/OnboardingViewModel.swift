import Observation
import SwiftUI

/// First-run onboarding: disclaimer, cycle basics, and HealthKit. Mic and notifications are requested in context later.
@Observable
@MainActor
final class OnboardingViewModel {
    enum Step: Int, CaseIterable {
        case welcome
        case cycleInfo
        case healthKit
    }

    private(set) var step: Step = .welcome
    private(set) var isRequestingPermission = false

    func advance(from preferences: OnboardingPreferences) {
        guard let next = Step(rawValue: step.rawValue + 1) else {
            preferences.markCompleted()
            return
        }
        step = next
    }

    func skipToEnd(from preferences: OnboardingPreferences) {
        preferences.markCompleted()
    }

    func requestHealthKit(cycleService: CycleService, appLock: AppLockController) async {
        isRequestingPermission = true
        appLock.beginHealthKitAuthorizationFlow()
        defer {
            isRequestingPermission = false
            appLock.endPermissionFlow()
        }
        await cycleService.requestAuthorization()
    }
}
