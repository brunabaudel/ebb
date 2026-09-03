import SwiftUI

/// Guided I+L+J+K logging flow for new entries.
struct GuidedLogFlowView: View {
    let schema: SchemaConfig
    @Binding var values: [String: FieldValue]
    let entries: [SymptomEntry]
    let onSave: () -> Void
    let onTalk: () -> Void

    @Environment(\.theme) private var theme
    @Environment(CycleService.self) private var cycleService

    @State private var step: LogSymptomsFlowStep = .smartEntry
    @State private var suggestion: LogEntrySuggestion?

    private var overlay: CalendarCycleOverlay {
        cycleService.makeOverlay(from: entries)
    }

    private var hasHeadache: Bool {
        values["migraine_present"] == .boolean(true)
    }

    private var showsHeadacheDetailSteps: Bool {
        hasHeadache
    }

    private var activeSteps: [LogSymptomsFlowStep] {
        switch values["migraine_present"] {
        case .boolean(true):
            LogSymptomsFlowStep.questionSteps(hasHeadache: true)
        case .boolean(false):
            LogSymptomsFlowStep.questionSteps(hasHeadache: false)
        default:
            LogSymptomsFlowStep.questionSteps(hasHeadache: true)
        }
    }

    private var progressFraction: Double {
        guard step != .smartEntry,
              let index = step.index(in: activeSteps),
              activeSteps.count > 1
        else { return 0 }
        return Double(index + 1) / Double(activeSteps.count)
    }

    private var progressLabel: String {
        guard step != .smartEntry,
              let index = step.index(in: activeSteps)
        else { return "" }
        return "\(index + 1) / \(activeSteps.count)"
    }

    var body: some View {
        VStack(spacing: 0) {
            if step != .smartEntry {
                sentenceStrip
            }

            ScrollView {
                stepContent
                    .padding(20)
            }

            if step == .review {
                saveBar
            }
        }
        .background(theme.base)
        .onAppear {
            suggestion = LogEntrySuggestionEngine.suggest(
                entries: entries,
                schema: schema,
                overlay: overlay
            )
        }
    }

    // MARK: - Sentence strip (J)

    private var sentenceStrip: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("BUILDING ENTRY · TAP A WORD TO EDIT")
                .font(.caption2.weight(.semibold))
                .kerning(1.2)
                .foregroundStyle(theme.muted)

            FlowLayout(spacing: 0) {
                ForEach(LogSymptomsSentenceBuilder.segments(values: values, schema: schema)) { segment in
                    if segment.isFilled || segment.step != nil {
                        Button {
                            if let target = segment.step {
                                step = target
                            }
                        } label: {
                            Text(segment.text)
                                .font(.system(.subheadline, design: .serif))
                                .fontWeight(segment.isFilled ? .semibold : .regular)
                                .foregroundStyle(segmentColor(for: segment))
                                .underline(segment.step != nil && segment.isFilled, pattern: .dot)
                        }
                        .buttonStyle(.plain)
                        .disabled(segment.step == nil)
                    } else {
                        Text(segment.text)
                            .font(.system(.subheadline, design: .serif))
                            .foregroundStyle(theme.muted)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(theme.surface)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(theme.line)
                .frame(height: 1)
        }
    }

    private func segmentColor(for segment: SentenceSegment) -> Color {
        if !segment.isFilled { return theme.muted }
        switch segment.accent {
        case .pain: return theme.pain
        case .cycle: return theme.cycle
        }
    }

    // MARK: - Step content

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case .smartEntry:
            smartEntryStep
        case .headachePresent:
            headacheStep
        case .severity:
            severityStep
        case .location:
            locationStep
        case .qualityAndMovement:
            qualityStep
        case .cycleAndContext:
            cycleContextStep
        case .review:
            reviewStep
        }
    }

    // MARK: L · Smart entry

    private var smartEntryStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let suggestion {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        Text(suggestion.phaseLabel.uppercased())
                            .font(.caption2.weight(.semibold))
                            .kerning(1.2)
                            .foregroundStyle(theme.cycle)
                        if let day = suggestion.cycleDay {
                            Text("· DAY \(day)")
                                .font(.caption2.weight(.semibold))
                                .kerning(1.2)
                                .foregroundStyle(theme.muted)
                        }
                    }

                    Text(suggestion.bannerText)
                        .font(.subheadline)
                        .foregroundStyle(theme.text)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 10) {
                        Button {
                            applySuggestion(suggestion)
                        } label: {
                            Text("Log like last time")
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(theme.pain, in: RoundedRectangle(cornerRadius: 12))
                                .foregroundStyle(theme.onPain)
                        }
                        .buttonStyle(.plain)

                        Button {
                            beginBlankFlow()
                        } label: {
                            Text("Start blank")
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(theme.surface, in: RoundedRectangle(cornerRadius: 12))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(theme.line, lineWidth: 1)
                                }
                                .foregroundStyle(theme.text)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(14)
                .background(
                    LinearGradient(
                        colors: [theme.cycleDim, theme.painDim],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: RoundedRectangle(cornerRadius: 16)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(theme.cycle.opacity(0.35), lineWidth: 1)
                }
            } else {
                Text("Tap through a few quick questions — or say it out loud.")
                    .font(.footnote)
                    .foregroundStyle(theme.muted)

                Button(action: beginBlankFlow) {
                    Text("Start logging")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(theme.pain, in: RoundedRectangle(cornerRadius: 14))
                        .foregroundStyle(theme.onPain)
                }
                .buttonStyle(.plain)
            }

            talkCard
        }
    }

    private var talkCard: some View {
        Button(action: onTalk) {
            HStack(spacing: 12) {
                Image(systemName: "mic.fill")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(theme.onPain)
                    .frame(width: 44, height: 44)
                    .background(theme.pain, in: Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text("Talk instead")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(theme.text)
                    Text("Say how you feel")
                        .font(.caption)
                        .foregroundStyle(theme.muted)
                }

                Spacer(minLength: 0)
            }
            .padding(12)
            .background(theme.surface, in: RoundedRectangle(cornerRadius: 14))
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(theme.line, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: I · Focus steps

    private var headacheStep: some View {
        focusShell(
            title: "Any headache right now?",
            subtitle: "Skip if not — cycle and context come later."
        ) {
            HStack(spacing: 11) {
                bigChoiceButton(title: "Yes", isSelected: values["migraine_present"] == .boolean(true)) {
                    values["migraine_present"] = .boolean(true)
                }
                bigChoiceButton(title: "No", isSelected: values["migraine_present"] == .boolean(false)) {
                    values["migraine_present"] = .boolean(false)
                    clearHeadacheDetailFields()
                }
            }
        }
    }

    private var severityStep: some View {
        focusShell(
            title: "How bad is it?",
            subtitle: "1 is barely there. 5 is disabling."
        ) {
            if let field = severityField, let range = field.range {
                SeveritySliderControl(
                    range: range,
                    labels: field.scaleLabels,
                    selection: scaleBinding(for: "severity"),
                    accent: .pain
                )
            }
        }
    }

    private var locationStep: some View {
        focusShell(
            title: "Where does it hurt?",
            subtitle: "Tap one or more zones."
        ) {
            HeadLocationMapView(selectedKeys: locationBinding)
        }
    }

    private var qualityStep: some View {
        focusShell(
            title: "What does it feel like?",
            subtitle: "Pick one or more. Skip if you're not sure."
        ) {
            VStack(alignment: .leading, spacing: 18) {
                if let field = schema.field(forKey: "quality") {
                    FlowLayout(spacing: 7) {
                        ForEach(field.values) { option in
                            SelectablePill(
                                label: option.label,
                                isSelected: selectedChoices("quality").contains(option.key),
                                accent: .pain
                            ) {
                                toggleChoice(option.key, fieldKey: "quality")
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("WORSE WITH MOVEMENT?")
                        .font(.caption2.weight(.semibold))
                        .kerning(1.2)
                        .foregroundStyle(theme.muted)

                    HStack(spacing: 11) {
                        bigChoiceButton(
                            title: "Yes",
                            isSelected: values["worse_with_movement"] == .boolean(true)
                        ) {
                            values["worse_with_movement"] = .boolean(true)
                        }
                        bigChoiceButton(
                            title: "No",
                            isSelected: values["worse_with_movement"] == .boolean(false)
                        ) {
                            values["worse_with_movement"] = .boolean(false)
                        }
                    }
                }
            }
        }
    }

    private var cycleContextStep: some View {
        focusShell(
            title: "Anything else today?",
            subtitle: nil,
            alignTop: true
        ) {
            VStack(alignment: .leading, spacing: 18) {
                if let field = schema.field(forKey: "bleeding") {
                    fieldPills(field: field, accent: .cycle)
                }
                if let field = schema.field(forKey: "cramps_severity"), let range = field.range {
                    Text(field.label.uppercased())
                        .font(.caption2.weight(.semibold))
                        .kerning(1.2)
                        .foregroundStyle(theme.muted)
                    ScaleStepper(
                        range: range,
                        labels: field.scaleLabels,
                        selection: scaleBinding(for: field.key),
                        accent: .cycle
                    )
                }
                if let field = schema.field(forKey: "triggers") {
                    fieldPills(field: field, accent: .pain, limit: 4)
                }
                if let field = schema.field(forKey: "relief_taken") {
                    fieldPills(field: field, accent: .pain, limit: 4)
                }
            }
        }
    }

    private var reviewStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Ready to save?")
                .font(.system(.title3, design: .serif))
                .fontWeight(.medium)
                .frame(maxWidth: .infinity, alignment: .center)

            VStack(alignment: .leading, spacing: 12) {
                Text(LogSymptomsSentenceBuilder.reviewSentence(values: values, schema: schema))
                    .font(.system(.body, design: .serif))
                    .foregroundStyle(theme.text)
                    .fixedSize(horizontal: false, vertical: true)

                ForEach(LogSymptomsSentenceBuilder.unsetFieldLabels(values: values, schema: schema), id: \.label) { item in
                    HStack {
                        Text(item.label)
                            .foregroundStyle(theme.muted)
                        Spacer()
                        Text("Not set")
                            .foregroundStyle(theme.muted)
                            .italic()
                    }
                    .font(.subheadline)
                }
            }
            .padding(16)
            .background(theme.surface, in: RoundedRectangle(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(theme.line, lineWidth: 1)
            }

            Text("Tap the sentence strip above to change anything.")
                .font(.caption)
                .foregroundStyle(theme.muted)
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    // MARK: - Focus shell

    private func focusShell<Content: View>(
        title: String,
        subtitle: String?,
        alignTop: Bool = false,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(spacing: 0) {
            if step != .smartEntry {
                progressHeader
            }

            VStack(spacing: 16) {
                Text(title)
                    .font(.system(.title2, design: .serif))
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, alignment: .center)

                if let subtitle {
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(theme.muted)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, alignment: .center)
                }

                content()

                if step != .review {
                    stepNavigation(showSkip: true, nextTitle: nextButtonTitle) {
                        advance()
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: alignTop ? nil : .infinity, alignment: alignTop ? .top : .center)
        }
    }

    private var progressHeader: some View {
        HStack(spacing: 10) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(theme.line)
                        .frame(height: 3)
                    Capsule()
                        .fill(theme.pain)
                        .frame(width: geometry.size.width * progressFraction, height: 3)
                }
            }
            .frame(height: 3)

            Text(progressLabel)
                .font(.caption2.monospaced())
                .foregroundStyle(theme.muted)
        }
        .padding(.bottom, 8)
    }

    private func stepNavigation(
        showSkip: Bool,
        nextTitle: String,
        onNext: @escaping () -> Void
    ) -> some View {
        HStack {
            if canGoBack {
                Button("← Back") { goBack() }
                    .font(.subheadline)
                    .foregroundStyle(theme.muted)
            } else {
                Color.clear.frame(width: 44)
            }

            Spacer()

            if showSkip {
                Button("Skip") { advance() }
                    .font(.subheadline)
                    .foregroundStyle(theme.muted)
            }

            Button(nextTitle, action: onNext)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(theme.onPain)
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .background(theme.pain, in: RoundedRectangle(cornerRadius: 12))
        }
        .padding(.top, 8)
    }

    private var saveBar: some View {
        VStack(spacing: 0) {
            Divider().overlay(theme.line)
            Button(action: onSave) {
                Text("Save entry")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(theme.pain, in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(theme.onPain)
            }
            .buttonStyle(.plain)
            .padding(20)
        }
    }

    // MARK: - Helpers

    private var severityField: SchemaField? {
        schema.field(forKey: "severity")
    }

    private var nextButtonTitle: String {
        if step == .cycleAndContext { return "Review →" }
        if step == activeSteps.dropLast().last { return "Review →" }
        return "Next →"
    }

    private var canGoBack: Bool {
        guard step != .smartEntry,
              let index = step.index(in: activeSteps)
        else { return false }
        return index > 0
    }

    private func bigChoiceButton(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.body.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(isSelected ? theme.pain : Color.clear, in: RoundedRectangle(cornerRadius: 16))
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(isSelected ? theme.pain : theme.line, lineWidth: 1)
                }
                .foregroundStyle(isSelected ? theme.onPain : theme.muted)
        }
        .buttonStyle(.plain)
    }

    private func fieldPills(field: SchemaField, accent: FieldAccent, limit: Int? = nil) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(field.label.uppercased())
                .font(.caption2.weight(.semibold))
                .kerning(1.2)
                .foregroundStyle(theme.muted)

            FlowLayout(spacing: 7) {
                ForEach(Array(field.values.prefix(limit ?? field.values.count))) { option in
                    SelectablePill(
                        label: option.label,
                        isSelected: isFieldSelected(field: field, key: option.key),
                        accent: accent
                    ) {
                        toggleField(field, key: option.key)
                    }
                }
            }
        }
    }

    private func applySuggestion(_ suggestion: LogEntrySuggestion) {
        values.merge(suggestion.fieldValues) { _, new in new }
        step = .headachePresent
    }

    private func beginBlankFlow() {
        step = .headachePresent
    }

    private func advance() {
        guard let index = step.index(in: activeSteps) else {
            if step == .smartEntry {
                step = .headachePresent
            }
            return
        }
        let nextIndex = index + 1
        if nextIndex < activeSteps.count {
            step = activeSteps[nextIndex]
        }
    }

    private func goBack() {
        guard let index = step.index(in: activeSteps), index > 0 else { return }
        step = activeSteps[index - 1]
    }

    private func clearHeadacheDetailFields() {
        for key in ["severity", "location", "quality", "worse_with_movement", "aura"] {
            values.removeValue(forKey: key)
        }
    }

    private func scaleBinding(for key: String) -> Binding<Int?> {
        Binding(
            get: {
                if case .scale(let step)? = values[key] { return step }
                return nil
            },
            set: { newValue in
                if let newValue {
                    values[key] = .scale(newValue)
                } else {
                    values.removeValue(forKey: key)
                }
            }
        )
    }

    private var locationBinding: Binding<Set<String>> {
        Binding(
            get: {
                if case .choices(let keys)? = values["location"] {
                    return Set(keys)
                }
                return []
            },
            set: { keys in
                if keys.isEmpty {
                    values.removeValue(forKey: "location")
                } else {
                    values["location"] = .choices(Array(keys).sorted())
                }
            }
        )
    }

    private func selectedChoices(_ key: String) -> Set<String> {
        if case .choices(let keys)? = values[key] { return Set(keys) }
        return []
    }

    private func toggleChoice(_ optionKey: String, fieldKey: String) {
        var keys = Array(selectedChoices(fieldKey))
        if let index = keys.firstIndex(of: optionKey) {
            keys.remove(at: index)
        } else {
            keys.append(optionKey)
        }
        values[fieldKey] = keys.isEmpty ? nil : .choices(keys)
    }

    private func isFieldSelected(field: SchemaField, key: String) -> Bool {
        switch field.type {
        case .singleEnum:
            return values[field.key] == .choice(key)
        case .multiEnum:
            return selectedChoices(field.key).contains(key)
        default:
            return false
        }
    }

    private func toggleField(_ field: SchemaField, key: String) {
        switch field.type {
        case .singleEnum:
            values[field.key] = values[field.key] == .choice(key) ? nil : .choice(key)
        case .multiEnum:
            toggleChoice(key, fieldKey: field.key)
        default:
            break
        }
    }
}

#Preview {
    @Previewable @State var values: [String: FieldValue] = [:]
    GuidedLogFlowView(
        schema: try! SchemaConfig.load(),
        values: $values,
        entries: [],
        onSave: {},
        onTalk: {}
    )
    .environment(\.theme, .plumEmber)
    .environment(CycleService(provider: MockCycleDataProvider()))
}
