import Foundation

/// Runtime flags shared by app entry, persistence, and privacy services.
enum AppRuntime {
    /// Test seam — lets unit tests exercise CloudKit-only code paths on the simulator.
    nonisolated(unsafe) static var forceCloudKitSyncForTesting = false

    static var isRunningTests: Bool {
        let env = ProcessInfo.processInfo.environment
        return env["XCTestConfigurationFilePath"] != nil
            || env["XCTestBundlePath"] != nil
            || env["XCTestSessionIdentifier"] != nil
    }

    /// StoreKitTest's `SKTestSession` aborts when the XCTest dylib is not loaded (e.g. simctl launch).
    static var isXCTestRuntimeLoaded: Bool {
        NSClassFromString("XCTestCase") != nil
    }

    /// CloudKit entitlements are not applied in unsigned simulator CI builds
    /// (`CODE_SIGNING_ALLOWED=NO`). Sync stays enabled on signed device builds.
    static var shouldUseCloudKitSync: Bool {
        if forceCloudKitSyncForTesting {
            return true
        }
        #if targetEnvironment(simulator)
        return false
        #else
        return !isRunningTests
        #endif
    }
}
