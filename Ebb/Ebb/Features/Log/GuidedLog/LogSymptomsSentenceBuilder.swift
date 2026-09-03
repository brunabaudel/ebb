import Foundation

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
            result.append(SentenceSegment(id: "sep1", text: " · ", isFilled: true, step: nil, accent: .pain))
            result.append(bleedingSegment(values: values, schema: schema))
            return result
        }

        if let severity = scaleValue(values["severity"]) {
            result.append(SentenceSegment(
                id: "severity",
                text: "\(severity)/5",
                isFilled: true,
                step: .severity,
                accent: .pain
            ))
            result.append(SentenceSegment(id: "sep2", text: " headache", isFilled: true, step: nil, accent: .pain))
        } else {
            result.append(SentenceSegment(
                id: "severity",
                text: "—/5 headache",
                isFilled: false,
                step: .severity,
                accent: .pain
            ))
        }

        if let location = choiceLabels(values["location"], fieldKey: "location", schema: schema) {
            result.append(SentenceSegment(id: "sep3", text: " on my ", isFilled: true, step: nil, accent: .pain))
            result.append(SentenceSegment(
                id: "location",
                text: location,
                isFilled: true,
                step: .location,
                accent: .pain
            ))
        } else if hasHeadache == true {
            result.append(SentenceSegment(id: "sep3b", text: " · ", isFilled: true, step: nil, accent: .pain))
            result.append(SentenceSegment(
                id: "location",
                text: "location?",
                isFilled: false,
                step: .location,
                accent: .pain
            ))
        }

        if let quality = choiceLabels(values["quality"], fieldKey: "quality", schema: schema) {
            result.append(SentenceSegment(id: "sep4", text: ", ", isFilled: true, step: nil, accent: .pain))
            result.append(SentenceSegment(
                id: "quality",
                text: quality,
                isFilled: true,
                step: .qualityAndMovement,
                accent: .pain
            ))
        }

        result.append(SentenceSegment(id: "sep5", text: ". ", isFilled: true, step: nil, accent: .pain))
        result.append(bleedingSegment(values: values, schema: schema))

        if let triggers = choiceLabels(values["triggers"], fieldKey: "triggers", schema: schema) {
            result.append(SentenceSegment(id: "sep6", text: " · Triggers: ", isFilled: true, step: nil, accent: .pain))
            result.append(SentenceSegment(
                id: "triggers",
                text: triggers,
                isFilled: true,
                step: .cycleAndContext,
                accent: .pain
            ))
        }

        return result
    }

    static func reviewSentence(
        values: [String: FieldValue],
        schema: SchemaConfig
    ) -> String {
        guard booleanValue(values["migraine_present"]) == true else {
            var parts: [String] = ["No headache logged."]
            if let bleeding = choiceLabel(values["bleeding"], fieldKey: "bleeding", schema: schema),
               bleeding.lowercased() != "none" {
                parts.append("Bleeding: \(bleeding.lowercased()).")
            }
            if let triggers = choiceLabels(values["triggers"], fieldKey: "triggers", schema: schema) {
                parts.append("Triggers: \(triggers.lowercased()).")
            }
            return parts.joined(separator: " ")
        }

        var sentence = "I'm having a"

        if let severity = scaleValue(values["severity"]) {
            sentence += " \(severity)/5"
        }
        if let quality = choiceLabels(values["quality"], fieldKey: "quality", schema: schema) {
            sentence += " \(quality.lowercased())"
        }
        sentence += " headache"

        if let location = choiceLabels(values["location"], fieldKey: "location", schema: schema) {
            sentence += " on my \(location.lowercased())"
        }
        sentence += "."

        if let triggers = choiceLabels(values["triggers"], fieldKey: "triggers", schema: schema) {
            sentence += " Triggered by \(triggers.lowercased())."
        }

        if let bleeding = choiceLabel(values["bleeding"], fieldKey: "bleeding", schema: schema),
           bleeding.lowercased() != "none" {
            sentence += " Bleeding: \(bleeding.lowercased())."
        }

        return sentence
    }

    static func unsetFieldLabels(
        values: [String: FieldValue],
        schema: SchemaConfig
    ) -> [(label: String, step: LogSymptomsFlowStep)] {
        var unset: [(String, LogSymptomsFlowStep)] = []
        let hasHeadache = booleanValue(values["migraine_present"]) == true

        if hasHeadache {
            if values["aura"] == nil {
                unset.append(("Aura", .qualityAndMovement))
            }
        }
        if values["bleeding"] == nil {
            unset.append(("Bleeding", .cycleAndContext))
        }
        if values["relief_taken"] == nil {
            unset.append(("Relief taken", .cycleAndContext))
        }
        if !hasHeadache, values["triggers"] == nil {
            unset.append(("Triggers", .cycleAndContext))
        }
        return unset
    }

    // MARK: - Private

    private static func noHeadacheSegments(
        values: [String: FieldValue],
        schema: SchemaConfig
    ) -> [SentenceSegment] {
        [
            SentenceSegment(
                id: "migraine_present",
                text: "No headache",
                isFilled: true,
                step: .headachePresent,
                accent: .pain
            ),
            SentenceSegment(id: "sep", text: " · Bleeding: ", isFilled: true, step: nil, accent: .cycle),
            bleedingSegment(values: values, schema: schema)
        ]
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
