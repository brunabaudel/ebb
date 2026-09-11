import SwiftUI

/// Flat heat-row list item for today's logs — accent node, title + severity tint, time.
struct TodayEntryRow: View {
    let entry: SymptomEntry
    let schema: SchemaConfig

    @Environment(\.theme) private var theme
    @ScaledMetric(relativeTo: .caption2) private var severityIndicatorWidth: CGFloat = 14
    @ScaledMetric(relativeTo: .caption2) private var severityIndicatorHeight: CGFloat = 6

    private var accent: FieldAccent {
        DaySummaryBuilder.entryAccent(entry)
    }

    private var painSeverity: Int? {
        DaySummaryBuilder.painSeverity(for: entry)
    }

    private var severityLabel: String? {
        DaySummaryBuilder.todayRowSeverityLabel(entry, schema: schema)
    }

    private var rowTitle: String {
        DaySummaryBuilder.todayRowTitle(entry, schema: schema)
    }

    private var cycleSummary: String? {
        DaySummaryBuilder.todayRowCycleSummary(entry, schema: schema)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(accent.accentColor(in: theme))
                .frame(width: 10, height: 10)
                .shadow(color: accent.accentColor(in: theme).opacity(0.85), radius: 3)
                .padding(.top, 4)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(rowTitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(theme.text)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .layoutPriority(1)

                    if let painSeverity {
                        severityIndicator(level: painSeverity)
                            .fixedSize(horizontal: true, vertical: true)
                    }

                    Spacer(minLength: 8)

                    Text(entry.timestamp.formatted(date: .omitted, time: .shortened))
                        .font(.caption2.monospaced())
                        .foregroundStyle(theme.muted)
                        .fixedSize(horizontal: true, vertical: true)
                }

                if let cycleSummary {
                    Text(cycleSummary)
                        .font(.footnote)
                        .foregroundStyle(theme.muted)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 10)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    private func severityIndicator(level: Int) -> some View {
        let clamped = min(max(level, 1), 5)
        let voiceOverLabel = severityAccessibilityLabel(for: clamped)

        return Capsule()
            .fill(severityColor(for: clamped))
            .frame(width: severityIndicatorWidth, height: severityIndicatorHeight)
            .accessibilityLabel(voiceOverLabel)
    }

    /// Soft paper pain palette — lighter for low severity, stronger `theme.pain` for high.
    private func severityColor(for level: Int) -> Color {
        switch level {
        case 1, 2:
            return theme.isLight ? theme.painDim : theme.pain.opacity(0.45)
        case 3:
            return theme.pain.opacity(0.72)
        case 4:
            return theme.pain
        default:
            return theme.isLight ? theme.warmInk : theme.pain
        }
    }

    private func severityAccessibilityLabel(for level: Int) -> String {
        if let severityLabel {
            return "Severity \(severityLabel)"
        }
        return "Severity \(level) of 5"
    }

    private var accessibilityLabel: String {
        let time = entry.timestamp.formatted(date: .omitted, time: .shortened)
        var parts = [rowTitle]
        if let cycleSummary {
            parts.append(cycleSummary)
        }
        parts.append(time)
        if let painSeverity {
            parts.append(severityAccessibilityLabel(for: painSeverity))
        }
        return parts.joined(separator: ", ")
    }
}

#Preview {
    let schema = try! SchemaConfig.load()
    let migraine = SymptomEntry(
        schemaVersion: schema.schemaVersion,
        fieldValues: [
            "migraine_present": .boolean(true),
            "severity": .scale(4),
            "bleeding": .choice("spotting"),
            "location": .choices(["right"]),
            "quality": .choices(["throbbing"]),
            "associated_symptoms": .choices(["nausea"]),
            "relief_taken": .choices(["ibuprofen"]),
        ],
        cyclePhase: .luteal
    )
    let spotting = SymptomEntry(
        schemaVersion: schema.schemaVersion,
        fieldValues: [
            "migraine_present": .boolean(false),
            "bleeding": .choice("spotting"),
            "cramps_severity": .scale(2),
        ],
        cyclePhase: .luteal
    )
    return VStack(spacing: 0) {
        TodayEntryRow(entry: migraine, schema: schema)
        Divider()
        TodayEntryRow(entry: spotting, schema: schema)
    }
    .padding(.horizontal)
    .background(Theme.softPaper.base)
    .environment(\.theme, .softPaper)
}
