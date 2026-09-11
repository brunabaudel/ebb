import Foundation

/// Aura multi-select rules: "No aura" (`none`) is mutually exclusive with other aura types.
enum AuraChoices {
    static let fieldKey = "aura"
    static let noneKey = "none"

    /// Toggles one aura option. Returns `nil` when no options remain selected.
    static func toggle(in choices: [String], optionKey: String) -> [String]? {
        if choices.contains(optionKey) {
            let updated = choices.filter { $0 != optionKey }
            return updated.isEmpty ? nil : updated
        }
        if optionKey == noneKey {
            return [noneKey]
        }
        var updated = choices.filter { $0 != noneKey }
        updated.append(optionKey)
        return updated
    }
}
