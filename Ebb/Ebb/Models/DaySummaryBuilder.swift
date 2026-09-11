import Foundation

/// Template-driven plain-language summaries for Today. The app computes the
/// facts; no model phrasing (product spec: summaries are the weak spot for
/// small local models).
enum DaySummaryBuilder {
    private static func choiceLabel(
        for key: String,
        in values: [String: FieldValue],
        schema: SchemaConfig
    ) -> String? {
        guard let field = schema.field(forKey: key) else { return nil }
        switch values[key] {
        case .choice(let choice):
            return field.values.first { $0.key == choice }?.label
        default:
            return nil
        }
    }

    // MARK: - Today row presentation

    static func entryAccent(_ entry: SymptomEntry) -> FieldAccent {
        let values = entry.fieldValues
        if values["migraine_present"] == .boolean(true) {
            return .pain
        }
        if let bleeding = values["bleeding"],
           case .choice(let key) = bleeding,
           key != "none" {
            return .cycle
        }
        if case .scale(let step)? = values["cramps_severity"], step > 0 {
            return .cycle
        }
        return .pain
    }

    static func todayRowTitle(_ entry: SymptomEntry, schema: SchemaConfig) -> String {
        if entry.hasCorruptFieldValues {
            return "Symptom log (data unreadable)"
        }
        let values = entry.fieldValues
        if values["migraine_present"] == .boolean(true) {
            return "Migraine"
        }
        if values["migraine_present"] == .boolean(false) {
            return "No migraine"
        }
        return "Symptom log"
    }

    static func todayRowDetail(_ entry: SymptomEntry, schema: SchemaConfig) -> String? {
        todayRowSeverityLabel(entry, schema: schema)
    }

    /// Lowercase severity scale label for migraine rows (e.g. "moderate").
    static func todayRowSeverityLabel(_ entry: SymptomEntry, schema: SchemaConfig) -> String? {
        let values = entry.fieldValues
        guard values["migraine_present"] == .boolean(true),
              case .scale(let step)? = values["severity"],
              let label = schema.field(forKey: "severity")?.scaleLabels[step] else {
            return nil
        }
        return label.lowercased()
    }

    /// Quiet cycle context for migraine-path Today rows — user-chosen bleeding only.
    static func todayRowCycleSummary(_ entry: SymptomEntry, schema: SchemaConfig) -> String? {
        let title = todayRowTitle(entry, schema: schema)
        guard title == "Migraine" || title == "No migraine" else { return nil }

        let values = entry.fieldValues
        guard let bleeding = choiceLabel(for: "bleeding", in: values, schema: schema),
              bleeding.lowercased() != "none" else {
            return nil
        }
        return bleeding.lowercased()
    }

    /// Tag chips for a Today row — pain / cycle / neutral, matching mock B markers.
    static func todayRowMarkers(_ entry: SymptomEntry, schema: SchemaConfig) -> [TodayRowMarker] {
        let values = entry.fieldValues
        var markers: [TodayRowMarker] = []

        if values["migraine_present"] == .boolean(true),
           case .scale(let step)? = values["severity"],
           let label = schema.field(forKey: "severity")?.scaleLabels[step] {
            markers.append(TodayRowMarker(label: label.lowercased(), kind: .pain))
        }

        for label in choiceLabelList(for: "location", in: values, schema: schema) {
            markers.append(TodayRowMarker(label: label.lowercased(), kind: .pain))
        }
        for label in choiceLabelList(for: "associated_symptoms", in: values, schema: schema) {
            markers.append(TodayRowMarker(label: label.lowercased(), kind: .pain))
        }

        if let bleeding = choiceLabel(for: "bleeding", in: values, schema: schema),
           bleeding.lowercased() != "none" {
            markers.append(TodayRowMarker(label: bleeding.lowercased(), kind: .cycle))
        }

        if case .scale(let step)? = values["cramps_severity"], step > 0,
           let label = schema.field(forKey: "cramps_severity")?.scaleLabels[step] {
            let title = todayRowTitle(entry, schema: schema)
            let chip = "\(label.lowercased()) cramps"
            if !title.localizedCaseInsensitiveContains("cramps") {
                markers.append(TodayRowMarker(label: chip, kind: .cycle))
            }
        }

        for label in choiceLabelList(for: "triggers", in: values, schema: schema) {
            markers.append(TodayRowMarker(label: label.lowercased(), kind: .neutral))
        }
        for label in choiceLabelList(for: "relief_taken", in: values, schema: schema) {
            markers.append(TodayRowMarker(label: label.lowercased(), kind: .neutral))
        }

        return markers
    }

    static func painSeverity(for entry: SymptomEntry) -> Int? {
        guard entry.fieldValues["migraine_present"] == .boolean(true),
              case .scale(let step)? = entry.fieldValues["severity"] else {
            return nil
        }
        return step
    }

    static func isCycleIntensityEntry(_ entry: SymptomEntry) -> Bool {
        entryAccent(entry) == .cycle && painSeverity(for: entry) == nil
    }

    private static func choiceLabelList(
        for key: String,
        in values: [String: FieldValue],
        schema: SchemaConfig
    ) -> [String] {
        guard let field = schema.field(forKey: key) else { return [] }
        switch values[key] {
        case .choices(let keys):
            return keys.compactMap { choice in
                field.values.first { $0.key == choice }?.label
            }
        case .choice(let key):
            if let label = field.values.first(where: { $0.key == key })?.label {
                return [label]
            }
            return []
        default:
            return []
        }
    }
}

/// Compact tag chip for Today / timeline-style entry rows (mock B markers).
struct TodayRowMarker: Equatable, Sendable, Identifiable {
    enum Kind: Equatable, Sendable {
        case pain
        case cycle
        case neutral
    }

    var id: String { "\(kind)-\(label)" }
    let label: String
    let kind: Kind
}
