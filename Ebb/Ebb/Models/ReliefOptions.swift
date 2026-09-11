import Foundation

/// User-defined medication / relief option stored outside the bundled schema.
struct CustomReliefOption: Codable, Equatable, Identifiable, Sendable {
    let key: String
    let label: String

    var id: String { key }
}

/// Schema relief options combined with user-defined custom reliefs.
enum ReliefOptions {
    static func schemaValues(from schema: SchemaConfig) -> [FieldValueOption] {
        schema.field(forKey: ReliefEffects.takenFieldKey)?.values ?? []
    }

    static func all(
        from schema: SchemaConfig,
        customReliefs: [CustomReliefOption]
    ) -> [FieldValueOption] {
        schemaValues(from: schema) + customReliefs.map {
            FieldValueOption(key: $0.key, label: $0.label, synonyms: [])
        }
    }

    static func allowedKeys(
        from schema: SchemaConfig,
        customReliefs: [CustomReliefOption]
    ) -> Set<String> {
        Set(all(from: schema, customReliefs: customReliefs).map(\.key))
    }

    static func label(
        for key: String,
        schema: SchemaConfig,
        customReliefs: [CustomReliefOption]
    ) -> String? {
        all(from: schema, customReliefs: customReliefs).first { $0.key == key }?.label
    }

    /// Returns an existing schema or custom key when `label` matches case-insensitively.
    static func existingKey(
        forLabel label: String,
        schema: SchemaConfig,
        customReliefs: [CustomReliefOption]
    ) -> String? {
        let trimmed = label.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return all(from: schema, customReliefs: customReliefs).first {
            $0.label.compare(trimmed, options: .caseInsensitive) == .orderedSame
        }?.key
    }

    static func makeCustomKey(reservedKeys: Set<String>) -> String {
        var key: String
        repeat {
            key = "custom_\(UUID().uuidString.lowercased())"
        } while reservedKeys.contains(key)
        return key
    }
}
