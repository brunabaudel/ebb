import SwiftData
import SwiftUI

struct SettingsView: View {
    let schema: SchemaConfig
    let schemaLoadResult: Result<SchemaConfig, Error>

    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(CycleService.self) private var cycleService
    @Environment(AppLockController.self) private var appLock
    @Environment(CloudSyncStatusService.self) private var cloudSyncStatus
    @Environment(EntitlementsService.self) private var entitlements
    @Environment(MedicationPreferences.self) private var medicationPreferences
    @Environment(ReminderPreferences.self) private var reminderPreferences
    @Query(sort: \SymptomEntry.timestamp, order: .reverse) private var entries: [SymptomEntry]

    @State private var showDebug = false
    @State private var showPaywall = false
    @State private var exportFile: ShareableFile?
    @State private var exportErrorMessage: String?
    @State private var showDeleteConfirmation = false
    @State private var deleteErrorMessage: String?
    @State private var syncPreferences = SyncPreferences()
    @State private var showSyncRestartAlert = false
    @State private var pendingSyncPreferenceValue = true

    var body: some View {
        NavigationStack {
            List {
                ebbPlusSection
                backupAndLockSection
                dataSection
                appearanceSection
                trackingSection
                healthKitSection
                cycleInfoSection

                #if DEBUG
                Section {
                    Button("Debug screen") {
                        showDebug = true
                    }
                    .themeListRow()
                } header: {
                    Text("Developer")
                }
                #endif
            }
            .themeSettingsList()
            .navigationTitle("Settings")
            .sheet(isPresented: $showDebug) {
                NavigationStack {
                    DebugScreen(schemaLoadResult: schemaLoadResult)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Done") { showDebug = false }
                            }
                        }
                }
                .themeSettingsScreen()
            }
            .sheet(item: $exportFile, onDismiss: cleanupExportFile) { file in
                ShareSheet(items: [file.url])
            }
            .sheet(isPresented: $showPaywall) {
                EbbPlusPaywallSheet()
            }
            .confirmationDialog(
                "Delete all symptom logs and reset cycle preferences?",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete everything", role: .destructive) {
                    deleteAllData()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text(deleteAllDataMessage)
            }
            .alert("Restart required", isPresented: $showSyncRestartAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(syncRestartMessage)
            }
            .task {
                await cycleService.refresh()
                await cloudSyncStatus.refresh()
            }
        }
        .themeSettingsScreen()
    }

    // MARK: - Ebb+

    private var ebbPlusSection: some View {
        Section {
            LabeledContent {
                Text(entitlements.isEbbPlus ? "Active" : "Free")
                    .foregroundStyle(entitlements.isEbbPlus ? theme.ok : theme.muted)
            } label: {
                Label("Ebb+", systemImage: "sparkles")
            }
            .themeListRow()

            if entitlements.isEbbPlus {
                Text("Patterns, doctor PDF, full history, and all themes are unlocked. Logging stays free forever.")
                    .font(.footnote)
                    .foregroundStyle(theme.muted)
                    .themeListRow()
            } else {
                Button("Unlock Ebb+") {
                    showPaywall = true
                }
                .themeListRow()
            }

            Button("Restore purchases") {
                Task {
                    try? await entitlements.restorePurchases()
                    if entitlements.isEbbPlus {
                        showPaywall = false
                    }
                }
            }
            .themeListRow()

            if let lastError = entitlements.lastErrorMessage {
                Text(lastError)
                    .font(.footnote)
                    .foregroundStyle(theme.pain)
                    .themeListRow()
            }
        } header: {
            Text("Ebb+")
        }
    }

    // MARK: - Appearance

    private var appearanceSection: some View {
        Section {
            NavigationLink {
                AppearanceSettingsView()
            } label: {
                Label("Appearance", systemImage: "paintpalette")
            }
            .themeListRow()
        }
    }

    // MARK: - Backup & lock

    private var backupAndLockSection: some View {
        Section {
            Toggle(isOn: iCloudSyncToggleBinding) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("iCloud backup & sync")

                    Text(cloudSyncStatus.statusLabel)
                        .foregroundStyle(iCloudStatusColor)

                    Text("Back up logs and sync iPhone and iPad via your Apple ID. Turn off to keep data on this device only.")
                        .font(.caption)
                        .foregroundStyle(theme.muted)
                }
            }
            .themeListRow()

            if showInlineBackupProgress {
                CloudBackupProgressView(
                    phaseLabel: cloudSyncStatus.backupPhaseLabel,
                    progress: cloudSyncStatus.backupProgress,
                    verificationStep: cloudSyncStatus.verificationStep,
                    verificationStepCount: cloudSyncStatus.verificationStepCount,
                    isIndeterminate: cloudSyncStatus.backupPhase == .uploading
                        && !cloudSyncStatus.isExportInProgress,
                    isExtendedConfirmation: cloudSyncStatus.isInExtendedBackupConfirmation
                )
                .themeListRow()
            }

            if let message = iCloudBackupMessage {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(iCloudMessageColor)
                    .fixedSize(horizontal: false, vertical: true)
                    .themeListRow()
            }

            if showRetryBackup {
                Button {
                    cloudSyncStatus.retryBackupAttempt()
                } label: {
                    Label("Retry backup", systemImage: "arrow.clockwise.icloud")
                }
                .themeListRow()
            }

            if syncPreferenceMismatch {
                Text("Quit and reopen Ebb to apply this change.")
                    .font(.footnote)
                    .foregroundStyle(theme.pain)
                    .themeListRow()
            }

            Toggle(isOn: appLockToggleBinding) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Lock with Face ID")

                    Text("Require Face ID, Touch ID, or your device passcode to open Ebb.")
                        .font(.caption)
                        .foregroundStyle(theme.muted)
                }
            }
            .themeListRow()
        }
    }

    private var iCloudStatusColor: Color {
        if cloudSyncStatus.hasConfirmedBackup {
            theme.ok
        } else if cloudSyncStatus.backupPhase == .stalled || cloudSyncStatus.lastBackupError != nil {
            theme.pain
        } else if cloudSyncStatus.isCloudKitSyncActive {
            theme.ok
        } else {
            theme.muted
        }
    }

    private var iCloudBackupMessage: String? {
        if cloudSyncStatus.restorePhase == .noBackupFound
            && cloudSyncStatus.statusLabel == "No iCloud backup found" {
            return "No backup found for this Apple ID yet. Add a log and wait for \"Backed up · iCloud\" before deleting the app."
        }
        if cloudSyncStatus.hasConfirmedBackup {
            return "Your logs are confirmed in your private iCloud database. They should return after reinstall on this Apple ID."
        }
        if showInlineBackupProgress {
            return cloudSyncStatus.lastBackupError
                ?? "Stay on Wi‑Fi and keep Ebb open until progress reaches 100%."
        }
        if cloudSyncStatus.isVerifyingBackup || cloudSyncStatus.statusLabel == "Backing up to iCloud…" {
            return cloudSyncStatus.lastBackupError
                ?? "Keep Ebb open on Wi‑Fi until this shows \"Backed up · iCloud\"."
        }
        if let lastBackupError = cloudSyncStatus.lastBackupError {
            return lastBackupError
        }
        return nil
    }

    private var iCloudMessageColor: Color {
        cloudSyncStatus.lastBackupError == nil ? theme.muted : theme.pain
    }

    private var showRetryBackup: Bool {
        cloudSyncStatus.isCloudKitSyncActive
            && cloudSyncStatus.trackedEntryCount > 0
            && !cloudSyncStatus.hasConfirmedBackup
    }

    private var showInlineBackupProgress: Bool {
        cloudSyncStatus.isCloudKitSyncActive
            && (cloudSyncStatus.isBackupInProgress
                || cloudSyncStatus.backupPhase == .stalled
                || cloudSyncStatus.statusLabel == "Backing up to iCloud…")
    }

    // MARK: - Data export / delete

    private var dataSection: some View {
        Section {
            Button {
                exportData()
            } label: {
                Label("Export JSON", systemImage: "square.and.arrow.up")
            }
            .themeListRow()

            if let exportErrorMessage {
                Text(exportErrorMessage)
                    .font(.footnote)
                    .foregroundStyle(theme.pain)
                    .themeListRow()
            }

            Button(role: .destructive) {
                showDeleteConfirmation = true
            } label: {
                Label("Delete all data", systemImage: "trash")
            }
            .themeListRow()

            if let deleteErrorMessage {
                Text(deleteErrorMessage)
                    .font(.footnote)
                    .foregroundStyle(theme.pain)
                    .themeListRow()
            }

            Text(exportDeleteFootnote)
                .font(.footnote)
                .foregroundStyle(theme.muted)
                .themeListRow()
        } header: {
            Text("Your data")
        }
    }

    private var deleteAllDataMessage: String {
        if cloudSyncStatus.isCloudKitSyncActive {
            return "This removes every entry from this device and your iCloud backup. It cannot be undone."
        }
        return "This removes every entry from this device. It cannot be undone."
    }

    private var exportDeleteFootnote: String {
        if cloudSyncStatus.isCloudKitSyncActive {
            return "Export a portable copy of your logs, or delete everything from this device and iCloud."
        }
        return "Export a portable copy of your logs, or delete everything stored on this device."
    }

    private var syncPreferenceMismatch: Bool {
        switch cloudSyncStatus.storageMode {
        case .cloudKit:
            return !syncPreferences.iCloudSyncEnabled
        case .localByChoice:
            return syncPreferences.iCloudSyncEnabled
        default:
            return false
        }
    }

    private var syncRestartMessage: String {
        if pendingSyncPreferenceValue {
            return "Ebb will sync via iCloud the next time you open it. Your existing iCloud backup is still there if you had one."
        }
        return "New logs will stay on this device only the next time you open Ebb. Any existing iCloud backup stays in your Apple ID until you turn sync back on."
    }

    private var iCloudSyncToggleBinding: Binding<Bool> {
        Binding(
            get: { syncPreferences.iCloudSyncEnabled },
            set: { newValue in
                guard newValue != syncPreferences.iCloudSyncEnabled else { return }
                pendingSyncPreferenceValue = newValue
                syncPreferences.iCloudSyncEnabled = newValue
                showSyncRestartAlert = true
            }
        )
    }

    private var appLockToggleBinding: Binding<Bool> {
        Binding(
            get: { appLock.isEnabled },
            set: { newValue in
                if newValue {
                    Task {
                        // Wait for the toggle animation to finish before Face ID.
                        try? await Task.sleep(for: .milliseconds(400))
                        _ = await appLock.enableAfterAuthentication()
                    }
                } else {
                    appLock.isEnabled = false
                }
            }
        )
    }

    private func exportData() {
        exportErrorMessage = nil

        guard case .success(let schema) = schemaLoadResult else {
            exportErrorMessage = "Could not load the symptom schema."
            return
        }

        do {
            let url = try SymptomDataExporter.makeTemporaryExportFile(
                entries: entries,
                schemaVersion: schema.schemaVersion,
                preferences: cycleService.preferences
            )
            exportFile = ShareableFile(url: url)
        } catch {
            exportErrorMessage = error.localizedDescription
        }
    }

    private func deleteAllData() {
        deleteErrorMessage = nil
        do {
            try SymptomDataExporter.deleteAllData(
                modelContext: modelContext,
                preferences: cycleService.preferences,
                medicationPreferences: medicationPreferences,
                reminderPreferences: reminderPreferences
            )
        } catch {
            deleteErrorMessage = error.localizedDescription
        }
    }

    private func cleanupExportFile() {
        if let url = exportFile?.url {
            try? FileManager.default.removeItem(at: url)
        }
        exportFile = nil
    }

    // MARK: - Tracking

    private var trackingSection: some View {
        Section {
            NavigationLink {
                RemindersSettingsView(
                    schema: schema,
                    reminderPreferences: reminderPreferences
                )
            } label: {
                Label("Reminders", systemImage: "bell")
            }
            .themeListRow()

            NavigationLink {
                MedicationsSettingsView(
                    schema: schema,
                    medicationPreferences: medicationPreferences
                )
            } label: {
                Label {
                    Text("My medications")
                } icon: {
                    Image(systemName: "pills")
                }
            }
            .themeListRow()

            NavigationLink {
                DoctorExportView(schema: schema)
            } label: {
                Label("Bring to your doctor", systemImage: "doc.text")
            }
            .themeListRow()

            NavigationLink {
                AboutView()
            } label: {
                Label("About", systemImage: "info.circle")
            }
            .themeListRow()
        } header: {
            Text("Tracking")
        }
    }

    // MARK: - HealthKit

    private var healthKitSection: some View {
        Section {
            NavigationLink {
                HealthKitSettingsView()
            } label: {
                LabeledContent {
                    Text(healthKitSummaryStatusLabel)
                        .foregroundStyle(healthKitSummaryStatusColor)
                } label: {
                    Label("HealthKit", systemImage: "heart.text.square")
                }
            }
            .themeListRow()
        }
    }

    private var healthKitSummaryStatusLabel: String {
        switch cycleService.authorizationStatus {
        case .unavailable: "Unavailable"
        case .notDetermined: "Not connected"
        case .authorized:
            cycleService.healthKitPeriodDays.isEmpty ? "Connected (no data)" : "Connected"
        case .denied: "Needs permission"
        }
    }

    private var healthKitSummaryStatusColor: Color {
        switch cycleService.authorizationStatus {
        case .authorized: theme.ok
        case .denied: theme.pain
        default: theme.muted
        }
    }

    // MARK: - Cycle info

    private var cycleInfoSection: some View {
        @Bindable var preferences = cycleService.preferences

        return Section {
            Stepper(
                value: $preferences.typicalCycleLength,
                in: CyclePreferences.cycleLengthRange,
                step: 1
            ) {
                LabeledContent("Typical cycle length") {
                    Text("\(preferences.typicalCycleLength) days")
                }
            }
            .themeListRow()

            Stepper(
                value: $preferences.periodLength,
                in: CyclePreferences.periodLengthRange,
                step: 1
            ) {
                LabeledContent("Typical period length") {
                    Text("\(preferences.periodLength) days")
                }
            }
            .themeListRow()

            Text("Used when HealthKit has no recent flow data, and to predict your next period.")
                .font(.footnote)
                .foregroundStyle(theme.muted)
                .themeListRow()

            Toggle(isOn: $preferences.hasAura) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("I get migraine aura")
                    Text("Visual or sensory warning before a migraine. Recorded for your doctor export — Ebb never gives medical advice.")
                        .font(.caption)
                        .foregroundStyle(theme.muted)
                }
            }
            .themeListRow()
        } header: {
            Text("Cycle info")
        }
    }
}

#Preview {
    SettingsView(
        schema: try! SchemaConfig.load(),
        schemaLoadResult: Result { try SchemaConfig.load() }
    )
        .environment(\.theme, .softPaper)
        .environment(CycleService(provider: MockCycleDataProvider.lutealSample()))
        .environment(AppLockController())
        .environment(CloudSyncStatusService(storageMode: .localByChoice))
        .environment(EntitlementsService(previewIsEbbPlus: false, listenForUpdates: false))
        .environment(ThemePreferences())
        .environment(MedicationPreferences())
        .environment(ReminderPreferences())
        .modelContainer(for: SymptomEntry.self, inMemory: true)
}
