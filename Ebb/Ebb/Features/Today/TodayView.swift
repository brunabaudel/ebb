import SwiftData
import SwiftUI

struct TodayView: View {
    let schema: SchemaConfig

    @Environment(\.theme) private var theme
    @Environment(CycleService.self) private var cycleService
    @Environment(\.symptomClassifier) private var symptomClassifier
    @Environment(MedicationPreferences.self) private var medicationPreferences
    @Query(sort: \SymptomEntry.timestamp, order: .reverse) private var entries: [SymptomEntry]

    @State private var showTapLog = false
    @State private var showTalkLog = false
    @State private var showConfirm = false
    @State private var confirmViewModel: ConfirmViewModel?
    @State private var showCalendar = false
    @State private var selectedEntry: SymptomEntry?
    @State private var selectedIntensityBlock: Int? = TodayIntensityStrip.blockIndex(containing: .now)

    private var cycleSnapshot: CycleSnapshot {
        cycleService.snapshot(for: .now, entries: entries)
    }

    private var todaysEntries: [SymptomEntry] {
        let calendar = Calendar.current
        return entries
            .filter { calendar.isDate($0.timestamp, inSameDayAs: .now) }
            .sorted { $0.timestamp > $1.timestamp }
    }

    private var displayedEntries: [SymptomEntry] {
        guard let selectedIntensityBlock else { return todaysEntries }
        return TodayIntensityStrip.entries(todaysEntries, inBlock: selectedIntensityBlock)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    cycleRing
                    TodayIntensityStrip(
                        entries: todaysEntries,
                        selectedBlockIndex: $selectedIntensityBlock
                    )
                }
                .padding(20)

                ScrollView {
                    entriesSection
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                }
                .scrollIndicators(.hidden)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .background(theme.base)
            .foregroundStyle(theme.text)
            .toolbar(.hidden, for: .navigationBar)
            .overlay(alignment: .bottomTrailing) {
                talkFAB
                    .padding(.trailing, 20)
                    .padding(.bottom, 16)
            }
            .navigationDestination(isPresented: $showCalendar) {
                CalendarView(schema: schema)
            }
            .sheet(isPresented: $showTapLog) {
                TapLogView(
                    schema: schema,
                    openConfirmOnAppear: ProcessInfo.processInfo.hasLaunchArgumentAutoConfirmLog,
                    launchTranscript: ProcessInfo.processInfo.mockTranscriptText
                )
            }
            .sheet(isPresented: $showTalkLog) {
                TalkView(schema: schema) { transcript in
                    presentConfirm(for: transcript)
                }
            }
            .sheet(isPresented: $showConfirm, onDismiss: {
                confirmViewModel = nil
            }) {
                if let confirmViewModel {
                    ConfirmView(schema: schema, viewModel: confirmViewModel)
                }
            }
            .sheet(item: $selectedEntry) { entry in
                EntryOverviewView(schema: schema, entry: entry)
            }
            .onAppear {
                selectedIntensityBlock = TodayIntensityStrip.blockIndex(containing: .now)
                if ProcessInfo.processInfo.hasLaunchArgumentOpenCalendar {
                    showCalendar = true
                }
                if ProcessInfo.processInfo.hasLaunchArgumentAutoTapLog
                    || ProcessInfo.processInfo.hasLaunchArgumentAutoConfirmLog {
                    showTapLog = true
                }
                if ProcessInfo.processInfo.hasLaunchArgumentAutoTalkLog {
                    showTalkLog = true
                }
            }
        }
    }

    private var talkFAB: some View {
        Button {
            showTalkLog = true
        } label: {
            Image(systemName: "mic.fill")
                .font(.title3.weight(.semibold))
                .foregroundStyle(theme.onPain)
                .frame(width: 54, height: 54)
                .background(theme.pain, in: RoundedRectangle(cornerRadius: 18))
                .shadow(color: theme.pain.opacity(theme.fabShadowOpacity), radius: 12, y: 4)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Talk")
        .accessibilityHint("Say how you feel to start a log")
    }

    private func presentConfirm(for transcript: String) {
        confirmViewModel = ConfirmViewModel(
            transcript: transcript,
            schema: schema,
            classifier: symptomClassifier,
            medicationPreferences: medicationPreferences
        )
        showConfirm = true
    }

    @ViewBuilder
    private var cycleRing: some View {
        if let phase = cycleSnapshot.phase, let cycleDay = cycleSnapshot.cycleDay {
            CyclePhaseRing(
                phase: phase,
                cycleDay: cycleDay,
                cycleLength: cycleSnapshot.cycleLength,
                summary: cycleSnapshot.summary
            )
        } else {
            VStack(alignment: .leading, spacing: 4) {
                Text("Cycle")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(theme.cycle)
                Text(cycleSnapshot.summary)
                    .font(.caption)
                    .foregroundStyle(theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(theme.surface, in: RoundedRectangle(cornerRadius: 18))
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(theme.line, lineWidth: 1)
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Today")
                    .font(.system(.title, design: .serif))
                Button { showCalendar = true } label: {
                    HStack(spacing: 5) {
                        Text(Date.now.formatted(date: .complete, time: .omitted))
                        Image(systemName: "chevron.right")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(theme.cycle)
                    }
                    .font(.footnote)
                    .foregroundStyle(theme.muted)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Browse calendar history")
            }
            Spacer(minLength: 12)
            Button { showTapLog = true } label: {
                Image(systemName: "plus")
                    .font(.title2.weight(.light))
                    .foregroundStyle(theme.text)
                    .frame(width: 34, height: 34)
                    .background(theme.surface, in: RoundedRectangle(cornerRadius: 10))
                    .overlay {
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(theme.line, lineWidth: 1)
                    }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Log symptoms")
        }
    }

    @ViewBuilder
    private var entriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let selectedIntensityBlock {
                filteredSlotHeader(for: selectedIntensityBlock)
            }

            if todaysEntries.isEmpty {
                emptyState
            } else if displayedEntries.isEmpty {
                filteredEmptyState
            } else {
                VStack(spacing: 0) {
                    ForEach(displayedEntries) { entry in
                        Button { selectedEntry = entry } label: {
                            TodayEntryRow(entry: entry, schema: schema)
                        }
                        .buttonStyle(.plain)

                        if entry.id != displayedEntries.last?.id {
                            Divider().overlay(theme.line)
                        }
                    }
                }
            }
        }
    }

    private func filteredSlotHeader(for index: Int) -> some View {
        let range = TodayIntensityStrip.blockTimeRangeLabel(index: index)
        return HStack(spacing: 8) {
            Text(range)
                .font(.caption.monospaced().weight(.semibold))
                .foregroundStyle(theme.text)
            Spacer(minLength: 8)
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedIntensityBlock = nil
                }
            } label: {
                Text("Show all")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(theme.muted)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Show all logs")
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            EbbIllustrationWell(variant: .default, diameter: 108, mascotSize: 84)

            VStack(alignment: .leading, spacing: 6) {
                Text("Blank page — in a good way")
                    .font(.system(.headline, design: .serif))
                    .foregroundStyle(theme.text)

                Text("When something shows up — migraine, period day, or just how you slept — Talk or Tap.")
                    .font(.subheadline)
                    .foregroundStyle(theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Nothing logged yet today. Ebb is here. Tap plus or the microphone to log how you're feeling.")
    }

    private var filteredEmptyState: some View {
        Text("No logs in this time window.")
            .font(.subheadline)
            .foregroundStyle(theme.muted)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

}

#Preview("Empty") {
    TodayView(schema: try! SchemaConfig.load())
        .modelContainer(for: SymptomEntry.self, inMemory: true)
        .environment(\.theme, .plumEmber)
        .environment(CycleService(provider: MockCycleDataProvider.lutealSample()))
        .environment(SpeechCapture(provider: MockSpeechRecognizer(transcript: "")))
        .environment(MedicationPreferences())
        .environment(ReminderPreferences())
        .environment(\.symptomClassifier, SynonymSymptomClassifier())
}

#Preview("With entries") {
    let schema = try! SchemaConfig.load()
    let container = try! ModelContainer(for: SymptomEntry.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let calendar = Calendar.current
    let migraine = SymptomEntry(
        timestamp: calendar.date(bySettingHour: 21, minute: 8, second: 0, of: .now)!,
        schemaVersion: schema.schemaVersion,
        fieldValues: [
            "migraine_present": .boolean(true),
            "severity": .scale(4),
            "location": .choices(["right"]),
            "associated_symptoms": .choices(["nausea"]),
            "relief_taken": .choices(["ibuprofen"]),
        ]
    )
    let spotting = SymptomEntry(
        timestamp: calendar.date(bySettingHour: 14, minute: 15, second: 0, of: .now)!,
        schemaVersion: schema.schemaVersion,
        fieldValues: [
            "migraine_present": .boolean(false),
            "bleeding": .choice("spotting"),
            "cramps_severity": .scale(2),
        ],
        cyclePhase: .luteal
    )
    container.mainContext.insert(migraine)
    container.mainContext.insert(spotting)
    return TodayView(schema: schema)
        .modelContainer(container)
        .environment(\.theme, .plumEmber)
        .environment(CycleService(provider: MockCycleDataProvider.lutealSample()))
        .environment(SpeechCapture(provider: MockSpeechRecognizer(transcript: "")))
        .environment(MedicationPreferences())
        .environment(ReminderPreferences())
        .environment(\.symptomClassifier, SynonymSymptomClassifier())
}
