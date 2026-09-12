import Foundation
import Observation

/// Relief options the user takes regularly — pre-fill Confirm (build-plan Phase 9).
@Observable
final class MedicationPreferences {
    var savedReliefKeys: [String] {
        didSet { persist() }
    }

    var customReliefs: [CustomReliefOption] {
        didSet { persist() }
    }

    /// Built-in schema relief keys hidden from the Care medications grid.
    var hiddenReliefKeys: [String] {
        didSet { persist() }
    }

    /// Per-relief medication reminder schedules, keyed by relief option id.
    var reliefAlarmSchedules: [String: ReliefAlarmSchedule] {
        didSet { persist() }
    }

    /// When on, relief alarms stay quiet while a migraine is active today.
    var pauseAlarmsDuringMigraine: Bool {
        didSet { defaults.set(pauseAlarmsDuringMigraine, forKey: Keys.pauseAlarmsDuringMigraine) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        savedReliefKeys = defaults.stringArray(forKey: Keys.savedReliefKeys) ?? []
        customReliefs = Self.loadCustomReliefs(from: defaults)
        hiddenReliefKeys = defaults.stringArray(forKey: Keys.hiddenReliefKeys) ?? []
        reliefAlarmSchedules = Self.loadReliefAlarmSchedules(from: defaults)
        pauseAlarmsDuringMigraine = defaults.object(forKey: Keys.pauseAlarmsDuringMigraine) as? Bool ?? true
    }

    func isSaved(_ key: String) -> Bool {
        savedReliefKeys.contains(key)
    }

    func setSaved(_ key: String, isSaved: Bool) {
        if isSaved {
            guard !savedReliefKeys.contains(key) else { return }
            savedReliefKeys.append(key)
        } else {
            savedReliefKeys.removeAll { $0 == key }
        }
    }

    /// Adds a custom relief or selects an existing schema/custom match by label.
    @discardableResult
    func addCustomRelief(label: String, schema: SchemaConfig) -> String? {
        let trimmed = label.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if let existingKey = ReliefOptions.existingKey(
            forLabel: trimmed,
            schema: schema,
            customReliefs: customReliefs
        ) {
            hiddenReliefKeys.removeAll { $0 == existingKey }
            setSaved(existingKey, isSaved: true)
            return existingKey
        }

        let reserved = ReliefOptions.allowedKeys(from: schema, customReliefs: customReliefs)
        let key = ReliefOptions.makeCustomKey(reservedKeys: reserved)
        customReliefs.append(CustomReliefOption(key: key, label: trimmed))
        setSaved(key, isSaved: true)
        return key
    }

    func alarmSchedule(for key: String) -> ReliefAlarmSchedule? {
        reliefAlarmSchedules[key]
    }

    func formattedAlarmTime(for key: String) -> String? {
        reliefAlarmSchedules[key]?.formattedTime()
    }

    func formattedAlarmRepeat(for key: String) -> String? {
        reliefAlarmSchedules[key]?.formattedRepeat()
    }

    func formattedAlarmDuration(for key: String) -> String? {
        reliefAlarmSchedules[key]?.formattedDuration()
    }

    func setAlarmSchedule(for key: String, schedule: ReliefAlarmSchedule) {
        reliefAlarmSchedules[key] = schedule
    }

    func clearAlarm(for key: String) {
        reliefAlarmSchedules.removeValue(forKey: key)
        setSaved(key, isSaved: false)
    }

    /// Removes a medication from the grid. Custom reliefs are deleted; built-in schema options are hidden.
    func removeRelief(key: String) {
        setSaved(key, isSaved: false)
        clearAlarm(for: key)

        if key.hasPrefix("custom_") {
            customReliefs.removeAll { $0.key == key }
        } else {
            guard !hiddenReliefKeys.contains(key) else { return }
            hiddenReliefKeys.append(key)
        }
    }

    func resetToDefaults() {
        savedReliefKeys = []
        customReliefs = []
        hiddenReliefKeys = []
        reliefAlarmSchedules = [:]
        pauseAlarmsDuringMigraine = true
    }

    // MARK: - Private

    private enum Keys {
        static let savedReliefKeys = "ebb.medications.savedReliefKeys"
        static let customReliefs = "ebb.medications.customReliefs"
        static let hiddenReliefKeys = "ebb.medications.hiddenReliefKeys"
        static let reliefAlarmSchedules = "ebb.medications.reliefAlarmSchedules"
        static let pauseAlarmsDuringMigraine = "ebb.medications.pauseAlarmsDuringMigraine"
        static let legacyReliefAlarmTimes = "ebb.medications.reliefAlarmTimes"
    }

    private let defaults: UserDefaults

    private func persist() {
        defaults.set(savedReliefKeys, forKey: Keys.savedReliefKeys)
        defaults.set(hiddenReliefKeys, forKey: Keys.hiddenReliefKeys)
        if let data = try? JSONEncoder().encode(customReliefs) {
            defaults.set(data, forKey: Keys.customReliefs)
        } else {
            defaults.removeObject(forKey: Keys.customReliefs)
        }
        if let data = try? JSONEncoder().encode(reliefAlarmSchedules) {
            defaults.set(data, forKey: Keys.reliefAlarmSchedules)
        } else {
            defaults.removeObject(forKey: Keys.reliefAlarmSchedules)
        }
    }

    private static func loadCustomReliefs(from defaults: UserDefaults) -> [CustomReliefOption] {
        guard let data = defaults.data(forKey: Keys.customReliefs),
              let decoded = try? JSONDecoder().decode([CustomReliefOption].self, from: data) else {
            return []
        }
        return decoded
    }

    private static func loadReliefAlarmSchedules(from defaults: UserDefaults) -> [String: ReliefAlarmSchedule] {
        if let data = defaults.data(forKey: Keys.reliefAlarmSchedules),
           let decoded = try? JSONDecoder().decode([String: ReliefAlarmSchedule].self, from: data) {
            return decoded
        }

        guard let data = defaults.data(forKey: Keys.legacyReliefAlarmTimes),
              let legacy = try? JSONDecoder().decode([String: ReliefAlarmTime].self, from: data) else {
            return [:]
        }

        let today = Calendar.ebbCalendar.startOfDay(for: .now)
        return legacy.mapValues { time in
            ReliefAlarmSchedule(
                hour: time.hour,
                minute: time.minute,
                weekdays: ReliefAlarmSchedule.allWeekdays,
                startDate: today,
                endDate: nil
            )
        }
    }
}
