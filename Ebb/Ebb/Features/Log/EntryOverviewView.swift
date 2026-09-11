import SwiftUI

/// Read-only Soft paper overview for a saved log entry — shown before edit.
struct EntryOverviewView: View {
    let schema: SchemaConfig
    let entry: SymptomEntry

    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss

    @State private var showEdit = false

    private var title: String {
        DaySummaryBuilder.todayRowTitle(entry, schema: schema)
    }

    private var accent: FieldAccent {
        DaySummaryBuilder.entryAccent(entry)
    }

    private var painSeverity: Int? {
        DaySummaryBuilder.painSeverity(for: entry)
    }

    private var detailRows: [ReviewDetailRow] {
        LogSymptomsSentenceBuilder.filledDetailRows(values: entry.fieldValues, schema: schema)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerSection

                    if entry.hasCorruptFieldValues {
                        corruptDataBanner
                    }

                    if let note = entry.note, !note.isEmpty {
                        noteSection(note)
                    }

                    if detailRows.isEmpty {
                        emptyDetails
                    } else {
                        detailCard
                    }
                }
                .padding(20)
            }
            .background(theme.base)
            .foregroundStyle(theme.text)
            .navigationTitle("Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Edit") { showEdit = true }
                        .accessibilityHint("Opens the edit form for this entry")
                }
            }
            .sheet(isPresented: $showEdit) {
                TapLogView(schema: schema, entry: entry)
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                Circle()
                    .fill(accent.accentColor(in: theme))
                    .frame(width: 10, height: 10)
                    .shadow(color: accent.accentColor(in: theme).opacity(0.85), radius: 3)
                    .padding(.top, 6)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.system(.title2, design: .serif))
                        .foregroundStyle(theme.text)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(entry.timestamp.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption.monospaced())
                        .foregroundStyle(theme.muted)

                    if let phase = entry.cyclePhase {
                        Text(phase.displayName)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(theme.cycle)
                    }
                }
            }

            if let painSeverity {
                severityBar(level: painSeverity)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var detailCard: some View {
        VStack(spacing: 0) {
            ForEach(Array(detailRows.enumerated()), id: \.element.id) { index, row in
                if index > 0 {
                    Divider().overlay(theme.line)
                }
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text(row.label)
                        .foregroundStyle(theme.muted)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    detailValue(for: row)
                }
                .font(.system(size: 13))
                .padding(.vertical, 9)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
        .guidedReviewDetailCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(detailAccessibilityLabel)
    }

    private var detailAccessibilityLabel: String {
        detailRows.map { row in
            let valueText = row.valueLines?.map(\.displayText).joined(separator: ". ") ?? row.value
            return "\(row.label): \(valueText)"
        }.joined(separator: ". ")
    }

    @ViewBuilder
    private func detailValue(for row: ReviewDetailRow) -> some View {
        ReviewDetailValue(row: row)
    }

    private var emptyDetails: some View {
        Text("No symptom fields recorded.")
            .font(.subheadline)
            .foregroundStyle(theme.muted)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .guidedReviewDetailCard()
    }

    private var corruptDataBanner: some View {
        Text("Some saved symptom data couldn't be read.")
            .font(.footnote)
            .foregroundStyle(theme.pain)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func noteSection(_ note: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("You said")
                .font(.caption.weight(.semibold))
                .foregroundStyle(theme.muted)
            Text(TranscriptFormatting.forDisplay(note))
                .font(.subheadline)
                .foregroundStyle(theme.text)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(theme.surface, in: RoundedRectangle(cornerRadius: 12))
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(theme.line, lineWidth: 1)
                }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("You said: \(note)")
    }

    private func severityBar(level: Int) -> some View {
        let clamped = min(max(level, 1), 5)
        let fill = CGFloat(clamped) / 5

        return GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(theme.line)

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [theme.pain.opacity(0.55), theme.pain],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(geo.size.width * fill, 4))
            }
        }
        .frame(height: 4)
        .accessibilityLabel("Severity \(clamped) of 5")
    }
}

#Preview {
    let schema = try! SchemaConfig.load()
    let entry = SymptomEntry(
        schemaVersion: schema.schemaVersion,
        fieldValues: [
            "migraine_present": .boolean(true),
            "severity": .scale(4),
            "location": .choices(["right"]),
            "quality": .choices(["throbbing"]),
            "associated_symptoms": .choices(["nausea"]),
            "relief_taken": .choices(["ibuprofen", "rest_dark_room"]),
            "relief_effects": .stringMap(["ibuprofen": "partial", "rest_dark_room": "full"]),
        ],
        note: "Sharp pain after lunch.",
        cyclePhase: .luteal
    )
    return EntryOverviewView(schema: schema, entry: entry)
        .environment(\.theme, .softPaper)
}
