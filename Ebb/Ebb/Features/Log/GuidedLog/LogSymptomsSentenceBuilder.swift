import Foundation

/// One filled field row in the compact review detail card (sketch C).
struct ReviewDetailRow: Identifiable, Equatable, Sendable {
    let id: String
    let label: String
    let value: String
    let step: LogSymptomsFlowStep
    let accent: FieldAccent
}

/// One tappable fragment in the live sentence strip (mockup J).
struct SentenceSegment: Identifiable, Equatable, Sendable {
    let id: String
    let text: String
    let isFilled: Bool
    let step: LogSymptomsFlowStep?
    let accent: FieldAccent
}

enum LogSymptomsSentenceBuilder {
    static func segments(
        values: [String: FieldValue],
        schema: SchemaConfig
    ) -> [SentenceSegment] {
        let hasHeadache = booleanValue(values["migraine_present"])

        guard hasHeadache != false else {
            return noHeadacheSegments(values: values, schema: schema)
        }

        var result: [SentenceSegment] = []

        if hasHeadache == nil {
            result.append(SentenceSegment(
                id: "migraine_present",
                text: "headache?",
                isFilled: false,
                step: .headachePresent,
                accent: .pain
            ))
            appendSeparator(&result, id: "sep_early")
            result.append(contentsOf: contextSegments(values: values, schema: schema, includePlaceholders: true))
            return result
        }

        // Severity + headache
        if let severity = scaleValue(values["severity"]) {
            result.append(SentenceSegment(
                id: "severity",
                text: "\(severity)/5",
                isFilled: true,
                step: .headachePresent,
                accent: .pain
            ))
            result.append(SentenceSegment(id: "sep_headache", text: " headache", isFilled: true, step: nil, accent: .pain))
        } else {
            result.append(SentenceSegment(
                id: "severity",
                text: "—/5 headache",
                isFilled: false,
                step: .headachePresent,
                accent: .pain
            ))
        }

        // Location
        if let location = choiceLabels(values["location"], fieldKey: "location", schema: schema) {
            result.append(SentenceSegment(id: "sep_loc", text: " on my ", isFilled: true, step: nil, accent: .pain))
            result.append(SentenceSegment(
                id: "location",
                text: location,
                isFilled: true,
                step: .location,
                accent: .pain
            ))
        } else {
            appendSeparator(&result, id: "sep_loc_ph")
            result.append(SentenceSegment(
                id: "location",
                text: "location?",
                isFilled: false,
                step: .location,
                accent: .pain
            ))
        }

        // Quality
        if let quality = choiceLabels(values["quality"], fieldKey: "quality", schema: schema) {
            result.append(SentenceSegment(id: "sep_quality", text: ", ", isFilled: true, step: nil, accent: .pain))
            result.append(SentenceSegment(
                id: "quality",
                text: quality,
                isFilled: true,
                step: .headachePresent,
                accent: .pain
            ))
        } else {
            appendSeparator(&result, id: "sep_quality_ph")
            result.append(SentenceSegment(
                id: "quality",
                text: "quality?",
                isFilled: false,
                step: .headachePresent,
                accent: .pain
            ))
        }

        // Worse with movement
        appendSeparator(&result, id: "sep_movement")
        if let worse = booleanValue(values["worse_with_movement"]) {
            result.append(SentenceSegment(
                id: "worse_with_movement",
                text: worse ? "worse with movement" : "not worse with movement",
                isFilled: true,
                step: .headachePresent,
                accent: .pain
            ))
        } else {
            result.append(SentenceSegment(
                id: "worse_with_movement",
                text: "movement?",
                isFilled: false,
                step: .headachePresent,
                accent: .pain
            ))
        }

        // Aura
        appendSeparator(&result, id: "sep_aura")
        if let aura = choiceLabels(values["aura"], fieldKey: "aura", schema: schema) {
            result.append(SentenceSegment(
                id: "aura",
                text: "aura: \(aura)",
                isFilled: true,
                step: .aura,
                accent: .pain
            ))
        } else {
            result.append(SentenceSegment(
                id: "aura",
                text: "aura?",
                isFilled: false,
                step: .aura,
                accent: .pain
            ))
        }

        result.append(SentenceSegment(id: "sep_end_pain", text: ".", isFilled: true, step: nil, accent: .pain))
        appendSeparator(&result, id: "sep_context")
        result.append(contentsOf: contextSegments(values: values, schema: schema, includePlaceholders: true))

        return result
    }

    /// Filled schema fields for the compact review detail card (sketch C).
    static func filledDetailRows(
        values: [String: FieldValue],
        schema: SchemaConfig
    ) -> [ReviewDetailRow] {
        var rows: [ReviewDetailRow] = []
        let hasHeadache = booleanValue(values["migraine_present"])

        if let hasHeadache {
            rows.append(ReviewDetailRow(
                id: "migraine_present",
                label: fieldLabel("migraine_present", schema: schema, fallback: "Headache"),
                value: hasHeadache ? "Yes" : "No",
                step: .headachePresent,
                accent: .pain
            ))
        }

        if hasHeadache == true {
            if let severity = scaleValue(values["severity"]) {
                rows.append(ReviewDetailRow(
                    id: "severity",
                    label: fieldLabel("severity", schema: schema, fallback: "Severity"),
                    value: "\(severity)/5",
                    step: .headachePresent,
                    accent: .pain
                ))
            }
            if let location = choiceLabels(values["location"], fieldKey: "location", schema: schema) {
                rows.append(ReviewDetailRow(
                    id: "location",
                    label: fieldLabel("location", schema: schema, fallback: "Location"),
                    value: location,
                    step: .location,
                    accent: .pain
                ))
            }
            if let quality = choiceLabels(values["quality"], fieldKey: "quality", schema: schema) {
                rows.append(ReviewDetailRow(
                    id: "quality",
                    label: fieldLabel("quality", schema: schema, fallback: "Quality"),
                    value: quality,
                    step: .headachePresent,
                    accent: .pain
                ))
            }
            if let worse = booleanValue(values["worse_with_movement"]) {
                rows.append(ReviewDetailRow(
                    id: "worse_with_movement",
                    label: fieldLabel("worse_with_movement", schema: schema, fallback: "Movement"),
                    value: worse ? "Worse with movement" : "Not worse with movement",
                    step: .headachePresent,
                    accent: .pain
                ))
            }
            if let aura = choiceLabels(values["aura"], fieldKey: "aura", schema: schema) {
                rows.append(ReviewDetailRow(
                    id: "aura",
                    label: fieldLabel("aura", schema: schema, fallback: "Aura"),
                    value: aura,
                    step: .aura,
                    accent: .pain
                ))
            }
            if let other = choiceLabels(values["associated_symptoms"], fieldKey: "associated_symptoms", schema: schema) {
                rows.append(ReviewDetailRow(
                    id: "associated_symptoms",
                    label: fieldLabel("associated_symptoms", schema: schema, fallback: "Other symptoms"),
                    value: other,
                    step: .headachePresent,
                    accent: .pain
                ))
            }
            if let relief = reliefSummary(values: values, schema: schema) {
                rows.append(ReviewDetailRow(
                    id: "relief_taken",
                    label: fieldLabel("relief_taken", schema: schema, fallback: "Relief"),
                    value: relief,
                    step: .relief,
                    accent: .pain
                ))
            }
            if let triggers = choiceLabels(values["triggers"], fieldKey: "triggers", schema: schema) {
                rows.append(ReviewDetailRow(
                    id: "triggers",
                    label: fieldLabel("triggers", schema: schema, fallback: "Triggers"),
                    value: triggers,
                    step: .triggers,
                    accent: .pain
                ))
            }
        }

        if let bleeding = choiceLabel(values["bleeding"], fieldKey: "bleeding", schema: schema) {
            rows.append(ReviewDetailRow(
                id: "bleeding",
                label: fieldLabel("bleeding", schema: schema, fallback: "Bleeding"),
                value: bleeding,
                step: .cycleAndContext,
                accent: .cycle
            ))
        }
        if let cramps = scaleValue(values["cramps_severity"]) {
            let scaleLabel = schema.field(forKey: "cramps_severity")?.scaleLabels[cramps]
            let value = scaleLabel.map { "\($0) (\(cramps)/5)" } ?? "\(cramps)/5"
            rows.append(ReviewDetailRow(
                id: "cramps_severity",
                label: fieldLabel("cramps_severity", schema: schema, fallback: "Cramps"),
                value: value,
                step: .cycleAndContext,
                accent: .cycle
            ))
        }
        return rows
    }

    static func unsetFieldLabels(
        values: [String: FieldValue],
        schema: SchemaConfig
    ) -> [(label: String, step: LogSymptomsFlowStep)] {
        var unset: [(String, LogSymptomsFlowStep)] = []
        let hasHeadache = booleanValue(values["migraine_present"]) == true

        if hasHeadache {
            if values["severity"] == nil {
                unset.append(("Severity", .headachePresent))
            }
            if values["location"] == nil {
                unset.append(("Location", .location))
            }
            if values["quality"] == nil {
                unset.append(("Quality", .headachePresent))
            }
            if values["worse_with_movement"] == nil {
                unset.append(("Worse with movement", .headachePresent))
            }
            if values["aura"] == nil {
                unset.append(("Aura", .aura))
            }
            if values[ReliefEffects.takenFieldKey] == nil {
                unset.append(("Relief taken", .relief))
            } else if !allTakenReliefItemsHaveEffects(values: values) {
                unset.append(("Did it help?", .relief))
            }
            if values["triggers"] == nil {
                unset.append(("Triggers", .triggers))
            }
        }
        if values["bleeding"] == nil {
            unset.append(("Bleeding", .cycleAndContext))
        }
        if values["cramps_severity"] == nil {
            unset.append(("Cramps", .cycleAndContext))
        }
        return unset
    }

    // MARK: - Private

    private static func fieldLabel(_ key: String, schema: SchemaConfig, fallback: String) -> String {
        schema.field(forKey: key)?.label ?? fallback
    }

    private static func reliefSummary(
        values: [String: FieldValue],
        schema: SchemaConfig
    ) -> String? {
        let parts = perReliefSummaryParts(values: values, schema: schema)
        guard !parts.isEmpty else { return nil }
        return parts.joined(separator: ", ")
    }

    private static func perReliefSummaryParts(
        values: [String: FieldValue],
        schema: SchemaConfig
    ) -> [String] {
        guard let takenField = schema.field(forKey: ReliefEffects.takenFieldKey),
              case .choices(let takenKeys)? = values[ReliefEffects.takenFieldKey],
              !takenKeys.isEmpty else {
            return []
        }

        return takenKeys.compactMap { key in
            guard let label = takenField.values.first(where: { $0.key == key })?.label else { return nil }
            guard let effectKey = ReliefEffects.effect(for: key, in: values),
                  let effectLabel = choiceLabel(.choice(effectKey), fieldKey: ReliefEffects.legacyEffectFieldKey, schema: schema)
            else {
                return label
            }
            return "\(label) · \(effectLabel)"
        }
    }

    private static func allTakenReliefItemsHaveEffects(values: [String: FieldValue]) -> Bool {
        let taken = ReliefEffects.takenKeys(from: values)
        guard !taken.isEmpty else { return true }
        return taken.allSatisfy { ReliefEffects.effect(for: $0, in: values) != nil }
    }

    private static func noHeadacheSegments(
        values: [String: FieldValue],
        schema: SchemaConfig
    ) -> [SentenceSegment] {
        var result: [SentenceSegment] = [
            SentenceSegment(
                id: "migraine_present",
                text: "No headache",
                isFilled: true,
                step: .headachePresent,
                accent: .pain
            )
        ]
        appendSeparator(&result, id: "sep_no_headache")
        result.append(contentsOf: contextSegments(
            values: values,
            schema: schema,
            includePlaceholders: true,
            includeRelief: false
        ))
        return result
    }

    /// Bleeding and cramps — shared by headache and no-headache paths.
    /// Relief and triggers are included only on the headache path (`includeRelief: true`).
    private static func contextSegments(
        values: [String: FieldValue],
        schema: SchemaConfig,
        includePlaceholders: Bool,
        includeRelief: Bool = true
    ) -> [SentenceSegment] {
        var result: [SentenceSegment] = []

        // Relief (headache path only)
        if includeRelief, !ReliefEffects.takenKeys(from: values).isEmpty {
            let summaryParts = perReliefSummaryParts(values: values, schema: schema)
            let hasAllEffects = allTakenReliefItemsHaveEffects(values: values)
            result.append(SentenceSegment(
                id: "relief_taken",
                text: "Took \(summaryParts.joined(separator: ", "))",
                isFilled: hasAllEffects,
                step: .relief,
                accent: .pain
            ))
            if !hasAllEffects, includePlaceholders {
                result.append(SentenceSegment(id: "sep_effect_ph", text: " · ", isFilled: true, step: nil, accent: .pain))
                result.append(SentenceSegment(
                    id: "relief_effect",
                    text: "did it help?",
                    isFilled: false,
                    step: .relief,
                    accent: .pain
                ))
            }
        } else if includeRelief, includePlaceholders {
            result.append(SentenceSegment(
                id: "relief_taken",
                text: "relief?",
                isFilled: false,
                step: .relief,
                accent: .pain
            ))
        }

        if !result.isEmpty {
            appendSeparator(&result, id: "sep_after_relief")
        }

        // Triggers (headache path only)
        if includeRelief {
            if let triggers = choiceLabels(values["triggers"], fieldKey: "triggers", schema: schema) {
                result.append(SentenceSegment(id: "trig_label", text: "Triggers: ", isFilled: true, step: nil, accent: .pain))
                result.append(SentenceSegment(
                    id: "triggers",
                    text: triggers,
                    isFilled: true,
                    step: .triggers,
                    accent: .pain
                ))
            } else if includePlaceholders {
                result.append(SentenceSegment(
                    id: "triggers",
                    text: "triggers?",
                    isFilled: false,
                    step: .triggers,
                    accent: .pain
                ))
            }

            if !result.isEmpty || includePlaceholders {
                appendSeparator(&result, id: "sep_after_triggers")
            }
        }

        // Bleeding
        result.append(SentenceSegment(id: "bleed_label", text: "Bleeding: ", isFilled: true, step: nil, accent: .cycle))
        result.append(bleedingSegment(values: values, schema: schema))

        appendSeparator(&result, id: "sep_cramps")

        // Cramps
        if let cramps = scaleValue(values["cramps_severity"]) {
            let label = schema.field(forKey: "cramps_severity")?.scaleLabels[cramps]
            let text = label.map { "Cramps: \($0)" } ?? "Cramps: \(cramps)/5"
            result.append(SentenceSegment(
                id: "cramps_severity",
                text: text,
                isFilled: true,
                step: .cycleAndContext,
                accent: .cycle
            ))
        } else if includePlaceholders {
            result.append(SentenceSegment(
                id: "cramps_severity",
                text: "cramps?",
                isFilled: false,
                step: .cycleAndContext,
                accent: .cycle
            ))
        }

        // Drop trailing separator if the last append left nothing useful
        while result.last?.id.hasPrefix("sep_") == true {
            result.removeLast()
        }

        return result
    }

    private static func bleedingSegment(
        values: [String: FieldValue],
        schema: SchemaConfig
    ) -> SentenceSegment {
        if let label = choiceLabel(values["bleeding"], fieldKey: "bleeding", schema: schema) {
            return SentenceSegment(
                id: "bleeding",
                text: label,
                isFilled: true,
                step: .cycleAndContext,
                accent: .cycle
            )
        }
        return SentenceSegment(
            id: "bleeding",
            text: "—",
            isFilled: false,
            step: .cycleAndContext,
            accent: .cycle
        )
    }

    private static func appendSeparator(_ result: inout [SentenceSegment], id: String) {
        guard let last = result.last, !last.text.hasSuffix(" · "), last.text != " · " else { return }
        if last.text.hasSuffix(".") {
            result.append(SentenceSegment(id: id, text: " · ", isFilled: true, step: nil, accent: .pain))
        } else if last.text.hasSuffix(" ") {
            return
        } else {
            result.append(SentenceSegment(id: id, text: " · ", isFilled: true, step: nil, accent: .pain))
        }
    }

    private static func booleanValue(_ value: FieldValue?) -> Bool? {
        guard case .boolean(let flag)? = value else { return nil }
        return flag
    }

    private static func scaleValue(_ value: FieldValue?) -> Int? {
        guard case .scale(let step)? = value else { return nil }
        return step
    }

    private static func choiceLabel(
        _ value: FieldValue?,
        fieldKey: String,
        schema: SchemaConfig
    ) -> String? {
        guard case .choice(let key)? = value,
              let label = schema.field(forKey: fieldKey)?.values.first(where: { $0.key == key })?.label
        else { return nil }
        return label
    }

    private static func choiceLabels(
        _ value: FieldValue?,
        fieldKey: String,
        schema: SchemaConfig
    ) -> String? {
        guard case .choices(let keys)? = value, !keys.isEmpty else { return nil }
        let field = schema.field(forKey: fieldKey)
        let labels = keys.compactMap { key in
            field?.values.first(where: { $0.key == key })?.label
        }
        guard !labels.isEmpty else { return nil }
        if labels.count == 1 { return labels[0] }
        if labels.count == 2 { return "\(labels[0]) and \(labels[1])" }
        return labels.dropLast().joined(separator: ", ") + ", and " + (labels.last ?? "")
    }
}
