import Foundation

/// Canonical display order for symptom fields — shared by guided add, edit form,
/// and review/overview rows. Keeps UI surfaces aligned when schema JSON order drifts.
enum LogSymptomsFieldOrder {
    /// TapLog edit + review rows. `relief_effects` (string_map) is stored but rendered
    /// inside `ReliefTakenControl`; legacy `relief_effect` is excluded from edit.
    static let displayFieldKeys: [String] = [
        "migraine_present", "severity", "quality", "worse_with_movement",
        "location", "aura", "relief_taken", "relief_effect",
        "triggers", "bleeding", "cramps_severity", "associated_symptoms",
    ]

    /// Multi-select fields that use the checkmark list in guided flow and edit form.
    static let checklistMultiEnumKeys: Set<String> = [
        "location", "triggers", "associated_symptoms",
    ]

    /// Fields rendered by composite controls instead of standalone `FieldControl` rows.
    static let editExcludedFieldKeys: Set<String> = [
        ReliefEffects.legacyEffectFieldKey,
    ]

    static func orderedVisibleFields(
        in schema: SchemaConfig,
        values: [String: FieldValue],
        excludingTypes: Set<FieldType> = [.stringMap],
        excludingKeys: Set<String> = []
    ) -> [SchemaField] {
        let visibleByKey = Dictionary(
            uniqueKeysWithValues: schema.fields
                .filter {
                    !excludingTypes.contains($0.type)
                        && !excludingKeys.contains($0.key)
                        && AppliesWhenEvaluator.isVisible(field: $0, values: values)
                }
                .map { ($0.key, $0) }
        )
        return displayFieldKeys.compactMap { visibleByKey[$0] }
    }
}

/// Steps in the merged I+L+J+K guided logging flow (new entries only).
enum LogSymptomsFlowStep: Int, CaseIterable, Identifiable, Sendable {
    case headachePresent
    case severity
    case location
    case aura
    case relief
    case triggers
    case cycleAndContext
    case associatedSymptoms
    case review

    var id: Int { rawValue }

    /// Question steps for the guided flow.
    static func questionSteps(hasHeadache: Bool) -> [LogSymptomsFlowStep] {
        if hasHeadache {
            [
                .headachePresent, .location, .aura, .relief, .triggers,
                .cycleAndContext, .associatedSymptoms, .review,
            ]
        } else {
            [.headachePresent, .cycleAndContext, .associatedSymptoms, .review]
        }
    }

    func index(in steps: [LogSymptomsFlowStep]) -> Int? {
        steps.firstIndex(of: self)
    }
}
