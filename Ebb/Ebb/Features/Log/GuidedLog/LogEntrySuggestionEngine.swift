import Foundation

/// Pre-fill suggestion for “Log like last time” (mockup L).
struct LogEntrySuggestion: Equatable, Sendable {
    let bannerText: String
    let phaseLabel: String
    let cycleDay: Int?
    let fieldValues: [String: FieldValue]
}

enum LogEntrySuggestionEngine {
    /// Returns a suggestion when ≥2 migraine entries share the current cycle phase.
    static func suggest(
        entries: [SymptomEntry],
        schema: SchemaConfig,
        overlay: CalendarCycleOverlay,
        now: Date = .now
    ) -> LogEntrySuggestion? {
        guard overlay.anchorPeriodStart != nil else { return nil }
        guard let currentPhase = overlay.phase(for: now) else { return nil }

        let cycleEntries = overlay.entriesInCycle(containing: now, from: entries)
        let phaseMigraines = cycleEntries.filter { entry in
            PatternStatsEngine.isMigraine(entry)
                && PatternStatsEngine.resolvedPhase(for: entry, overlay: overlay) == currentPhase
        }
        guard phaseMigraines.count >= 2 else { return nil }

        var suggested: [String: FieldValue] = ["migraine_present": .boolean(true)]

        if let severity = modeScale(from: phaseMigraines, key: "severity") {
            suggested["severity"] = .scale(severity)
        }
        if let location = modeChoiceKeys(from: phaseMigraines, key: "location").first {
            suggested["location"] = .choices([location])
        }
        if let quality = modeChoiceKeys(from: phaseMigraines, key: "quality").first {
            suggested["quality"] = .choices([quality])
        }
        if let movement = modeBoolean(from: phaseMigraines, key: "worse_with_movement") {
            suggested["worse_with_movement"] = .boolean(movement)
        }
        if let trigger = PatternStatsEngine.rankedTriggers(
            from: phaseMigraines,
            schema: schema,
            limit: 1
        ).first?.key {
            suggested["triggers"] = .choices([trigger])
        }

        let banner = bannerText(
            from: phaseMigraines,
            schema: schema,
            phase: currentPhase
        )
        let phaseLabel = currentPhase.displayName
        let cycleDay = overlay.cycleDay(for: now)

        return LogEntrySuggestion(
            bannerText: banner,
            phaseLabel: phaseLabel,
            cycleDay: cycleDay,
            fieldValues: suggested
        )
    }

    // MARK: - Banner copy

    private static func bannerText(
        from entries: [SymptomEntry],
        schema: SchemaConfig,
        phase: CyclePhase
    ) -> String {
        let locationPhrase = dominantLocationPhrase(from: entries, schema: schema)
        let severityPhrase = dominantSeverityPhrase(from: entries)
        let qualityPhrase = dominantQualityPhrase(from: entries, schema: schema)
        let triggerPhrase = dominantTriggerPhrase(from: entries, schema: schema)

        var descriptors: [String] = []
        if let locationPhrase { descriptors.append(locationPhrase) }
        if let qualityPhrase { descriptors.append(qualityPhrase) }
        if let severityPhrase { descriptors.append(severityPhrase) }

        let core = descriptors.isEmpty
            ? "similar migraines"
            : descriptors.joined(separator: ", ")

        if let triggerPhrase {
            return "Your last \(entries.count) migraines in the \(phase.displayName.lowercased()) phase were \(core) — often after \(triggerPhrase.lowercased())."
        }
        return "Your last \(entries.count) migraines in the \(phase.displayName.lowercased()) phase were \(core)."
    }

    private static func dominantLocationPhrase(
        from entries: [SymptomEntry],
        schema: SchemaConfig
    ) -> String? {
        let keys = entries.flatMap { entry -> [String] in
            guard case .choices(let k) = entry.fieldValues["location"] else { return [] }
            return k
        }
        guard let key = mostCommon(in: keys),
              let label = schema.field(forKey: "location")?.values.first(where: { $0.key == key })?.label
        else { return nil }
        return label.lowercased()
    }

    private static func dominantQualityPhrase(
        from entries: [SymptomEntry],
        schema: SchemaConfig
    ) -> String? {
        let keys = entries.flatMap { entry -> [String] in
            guard case .choices(let k) = entry.fieldValues["quality"] else { return [] }
            return k
        }
        guard let key = mostCommon(in: keys),
              let label = schema.field(forKey: "quality")?.values.first(where: { $0.key == key })?.label
        else { return nil }
        return label.lowercased()
    }

    private static func dominantSeverityPhrase(from entries: [SymptomEntry]) -> String? {
        let values = entries.compactMap { entry -> Int? in
            guard case .scale(let step) = entry.fieldValues["severity"] else { return nil }
            return step
        }
        guard !values.isEmpty else { return nil }
        let avg = values.reduce(0, +) / values.count
        return "~\(avg)/5"
    }

    private static func dominantTriggerPhrase(
        from entries: [SymptomEntry],
        schema: SchemaConfig
    ) -> String? {
        let ranked = PatternStatsEngine.rankedTriggers(from: entries, schema: schema, limit: 1)
        return ranked.first?.label
    }

    // MARK: - Mode helpers

    private static func modeScale(from entries: [SymptomEntry], key: String) -> Int? {
        let values = entries.compactMap { entry -> Int? in
            guard case .scale(let step) = entry.fieldValues[key] else { return nil }
            return step
        }
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / values.count
    }

    private static func modeChoiceKeys(from entries: [SymptomEntry], key: String) -> [String] {
        let flat = entries.flatMap { entry -> [String] in
            guard case .choices(let keys) = entry.fieldValues[key] else { return [] }
            return keys
        }
        guard let common = mostCommon(in: flat) else { return [] }
        return [common]
    }

    private static func modeBoolean(from entries: [SymptomEntry], key: String) -> Bool? {
        let flags = entries.compactMap { entry -> Bool? in
            guard case .boolean(let flag) = entry.fieldValues[key] else { return nil }
            return flag
        }
        guard !flags.isEmpty else { return nil }
        let trueCount = flags.filter { $0 }.count
        return trueCount >= flags.count - trueCount
    }

    private static func mostCommon(in values: [String]) -> String? {
        guard !values.isEmpty else { return nil }
        let grouped = Dictionary(grouping: values, by: { $0 })
        return grouped.max(by: { $0.value.count < $1.value.count })?.key
    }
}
