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

    /// Per-relief daily alarm times (hour/minute), keyed by relief option id.
    var reliefAlarmTimes: [String: ReliefAlarmTime] {
        didSet { persist() }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        savedReliefKeys = defaults.stringArray(forKey: Keys.savedReliefKeys) ?? []
        customReliefs = Self.loadCustomReliefs(from: defaults)
        hiddenReliefKeys = defaults.stringArray(forKey: Keys.hiddenReliefKeys) ?? []
        reliefAlarmTimes = Self.loadReliefAlarmTimes(from: defaults)
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

    func alarmTime(for key: String) -> ReliefAlarmTime? {
        reliefAlarmTimes[key]
    }

    func setAlarmTime(for key: String, hour: Int, minute: Int) {
        reliefAlarmTimes[key] = ReliefAlarmTime(hour: hour, minute: minute)
    }

    func clearAlarm(for key: String) {
        reliefAlarmTimes.removeValue(forKey: key)
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
        reliefAlarmTimes = [:]
    }

    // MARK: - Private

    private enum Keys {
        static let savedReliefKeys = "ebb.medications.savedReliefKeys"
        static let customReliefs = "ebb.medications.customReliefs"
        static let hiddenReliefKeys = "ebb.medications.hiddenReliefKeys"
        static let reliefAlarmTimes = "ebb.medications.reliefAlarmTimes"
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
        if let data = try? JSONEncoder().encode(reliefAlarmTimes) {
            defaults.set(data, forKey: Keys.reliefAlarmTimes)
        } else {
            defaults.removeObject(forKey: Keys.reliefAlarmTimes)
        }
    }

    private static func loadCustomReliefs(from defaults: UserDefaults) -> [CustomReliefOption] {
        guard let data = defaults.data(forKey: Keys.customReliefs),
              let decoded = try? JSONDecoder().decode([CustomReliefOption].self, from: data) else {
            return []
        }
        return decoded
    }

    private static func loadReliefAlarmTimes(from defaults: UserDefaults) -> [String: ReliefAlarmTime] {
        guard let data = defaults.data(forKey: Keys.reliefAlarmTimes),
              let decoded = try? JSONDecoder().decode([String: ReliefAlarmTime].self, from: data) else {
            return [:]
        }
        return decoded
    }
}
