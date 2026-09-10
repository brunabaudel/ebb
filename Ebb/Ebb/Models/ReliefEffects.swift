import Foundation

/// Per-relief effect storage for guided logging.
///
/// New entries store a map under `relief_effects` (`reliefTakenKey → effectKey`).
/// Legacy entries use a single `relief_effect` choice applied to every taken item.
enum ReliefEffects {
    static let takenFieldKey = "relief_taken"
    static let legacyEffectFieldKey = "relief_effect"
    static let effectsFieldKey = "relief_effects"

    static func takenKeys(from values: [String: FieldValue]) -> [String] {
        guard case .choices(let keys)? = values[takenFieldKey] else { return [] }
        return keys
    }

    /// Resolved effect key for one taken relief item, honoring legacy single-choice data.
    static func effect(for reliefKey: String, in values: [String: FieldValue]) -> String? {
        if case .stringMap(let map)? = values[effectsFieldKey],
           let effect = map[reliefKey] {
            return effect
        }
        if case .choice(let legacy)? = values[legacyEffectFieldKey] {
            return legacy
        }
        return nil
    }

    static func effectsMap(in values: [String: FieldValue]) -> [String: String] {
        let taken = takenKeys(from: values)
        guard !taken.isEmpty else { return [:] }

        if case .stringMap(let stored)? = values[effectsFieldKey] {
            return taken.reduce(into: [:]) { result, key in
                if let effect = stored[key] {
                    result[key] = effect
                }
            }
        }

        if case .choice(let legacy)? = values[legacyEffectFieldKey] {
            return Dictionary(uniqueKeysWithValues: taken.map { ($0, legacy) })
        }

        return [:]
    }

    static func hasFullRelief(in values: [String: FieldValue]) -> Bool {
        let taken = takenKeys(from: values)
        guard !taken.isEmpty else { return false }
        return taken.contains { effect(for: $0, in: values) == "full" }
    }

    static func isHelpful(reliefKey: String, in values: [String: FieldValue]) -> Bool {
        guard let effect = effect(for: reliefKey, in: values) else { return false }
        return effect == "partial" || effect == "full"
    }

    static func sanitizedMap(
        _ map: [String: String],
        schema: SchemaConfig
    ) -> [String: String] {
        let allowedTaken = schema.field(forKey: takenFieldKey)?.allowedValueKeys ?? []
        let allowedEffects = schema.field(forKey: legacyEffectFieldKey)?.allowedValueKeys ?? []
        return map.reduce(into: [:]) { result, pair in
            guard allowedTaken.contains(pair.key),
                  allowedEffects.contains(pair.value) else { return }
            result[pair.key] = pair.value
        }
    }

    static func write(
        _ map: [String: String],
        to values: inout [String: FieldValue],
        schema: SchemaConfig
    ) {
        let sanitized = sanitizedMap(map, schema: schema)
        if sanitized.isEmpty {
            values.removeValue(forKey: effectsFieldKey)
        } else {
            values[effectsFieldKey] = .stringMap(sanitized)
        }
        values.removeValue(forKey: legacyEffectFieldKey)
    }

    static func clear(from values: inout [String: FieldValue]) {
        values.removeValue(forKey: effectsFieldKey)
        values.removeValue(forKey: legacyEffectFieldKey)
    }

    static func prune(toTakenKeys taken: Set<String>, in values: inout [String: FieldValue]) {
        guard case .stringMap(var map)? = values[effectsFieldKey] else {
            if taken.isEmpty {
                clear(from: &values)
            }
            return
        }
        map = map.filter { taken.contains($0.key) }
        if map.isEmpty {
            values.removeValue(forKey: effectsFieldKey)
        } else {
            values[effectsFieldKey] = .stringMap(map)
        }
    }
}
