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

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        savedReliefKeys = defaults.stringArray(forKey: Keys.savedReliefKeys) ?? []
        customReliefs = Self.loadCustomReliefs(from: defaults)
        hiddenReliefKeys = defaults.stringArray(forKey: Keys.hiddenReliefKeys) ?? []
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

    /// Removes a medication from the grid. Custom reliefs are deleted; built-in schema options are hidden.
    func removeRelief(key: String) {
        setSaved(key, isSaved: false)

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
    }

    // MARK: - Private

    private enum Keys {
        static let savedReliefKeys = "ebb.medications.savedReliefKeys"
        static let customReliefs = "ebb.medications.customReliefs"
        static let hiddenReliefKeys = "ebb.medications.hiddenReliefKeys"
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
    }

    private static func loadCustomReliefs(from defaults: UserDefaults) -> [CustomReliefOption] {
        guard let data = defaults.data(forKey: Keys.customReliefs),
              let decoded = try? JSONDecoder().decode([CustomReliefOption].self, from: data) else {
            return []
        }
        return decoded
    }
}
