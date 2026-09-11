import SwiftUI

/// Flat heat-row list item for today's logs — B timeline: node, title+time, severity chip.
struct TodayEntryRow: View {
    let entry: SymptomEntry
    let schema: SchemaConfig

    @Environment(\.theme) private var theme

    private var accent: FieldAccent {
        DaySummaryBuilder.entryAccent(entry)
    }

    private var severityLabel: String? {
        DaySummaryBuilder.todayRowSeverityLabel(entry, schema: schema)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(accent.accentColor(in: theme))
                .frame(width: 10, height: 10)
                .shadow(color: accent.accentColor(in: theme).opacity(0.85), radius: 3)
                .padding(.top, 4)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(DaySummaryBuilder.todayRowTitle(entry, schema: schema))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(theme.text)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text(entry.timestamp.formatted(date: .omitted, time: .shortened))
                        .font(.caption2.monospaced())
                        .foregroundStyle(theme.muted)
                }

                if let severityLabel {
                    severityChip(label: severityLabel)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 10)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    private func severityChip(label: String) -> some View {
        Text(label)
            .font(.caption2.monospaced())
            .foregroundStyle(theme.pain)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(theme.painDim, in: RoundedRectangle(cornerRadius: 6))
            .overlay {
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(theme.pain.opacity(0.45), lineWidth: 1)
            }
    }

    private var accessibilityLabel: String {
        let title = DaySummaryBuilder.todayRowTitle(entry, schema: schema)
        let time = entry.timestamp.formatted(date: .omitted, time: .shortened)
        var parts = ["\(title), \(time)"]
        if let severityLabel {
            parts.append(severityLabel)
        }
        return parts.joined(separator: ". ")
    }
}

#Preview {
    let schema = try! SchemaConfig.load()
    let migraine = SymptomEntry(
        schemaVersion: schema.schemaVersion,
        fieldValues: [
            "migraine_present": .boolean(true),
            "severity": .scale(4),
            "location": .choices(["right"]),
            "quality": .choices(["throbbing"]),
            "associated_symptoms": .choices(["nausea"]),
            "relief_taken": .choices(["ibuprofen"]),
        ]
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
    .background(Theme.plumEmber.base)
    .environment(\.theme, .plumEmber)
}
