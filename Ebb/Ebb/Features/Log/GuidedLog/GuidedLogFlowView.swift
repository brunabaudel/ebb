import SwiftUI

/// Guided I+L+J+K logging flow for new entries.
struct GuidedLogFlowView: View {
    let schema: SchemaConfig
    @Binding var values: [String: FieldValue]
    let onSave: () -> Void

    @Environment(\.theme) private var theme
    @Environment(MedicationPreferences.self) private var medicationPreferences

    @State private var step: LogSymptomsFlowStep = .headachePresent
    @State private var didApplyMedicationPrefill = false

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
        guard let index = step.index(in: activeSteps),
              activeSteps.count > 1
        else { return 0 }
        return Double(index + 1) / Double(activeSteps.count)
    }

    private var progressLabel: String {
        guard let index = step.index(in: activeSteps) else { return "" }
        return "\(index + 1) / \(activeSteps.count)"
    }

    var body: some View {
        VStack(spacing: 0) {
            if step != .review {
                VStack(spacing: 0) {
                    sentenceStrip
                        .padding(.horizontal, 20)
                        .padding(.top, 10)

                    progressHeader
                        .padding(.horizontal, 20)
                        .padding(.bottom, 18)
                }
            }

            Group {
                if step == .review {
                    ScrollView {
                        reviewStep
                            .padding(.horizontal, 20)
                            .padding(.top, 24)
                            .padding(.bottom, 16)
                            .frame(maxWidth: .infinity, alignment: .top)
                    }
                    .scrollIndicators(.hidden)
                } else {
                    ScrollView {
                        questionBody
                            .padding(.horizontal, 20)
                            .padding(.bottom, 16)
                            .frame(maxWidth: .infinity, alignment: .top)
                    }
                    .scrollIndicators(.hidden)
                }
            }
            .frame(maxHeight: .infinity)

            if step == .review {
                saveBar
            } else {
                stepNavigationBar
            }
        }
        .background(theme.base)
    }

    // MARK: - Sentence strip (g-strip)

    private var sentenceStrip: some View {
        entryPhrase(
            font: .system(size: 15, design: .serif),
            centered: false,
            allowsMultiline: true,
            bodyColor: theme.inkSoft
        )
        .lineSpacing(15 * 0.35)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .guidedSentenceStrip()
        .padding(.bottom, 14)
    }

    // MARK: - Entry phrase (review tap-to-edit)

    private func entryPhrase(
        font: Font,
        centered: Bool,
        allowsMultiline: Bool = false,
        bodyColor: Color? = nil
    ) -> some View {
        Group {
            if allowsMultiline {
                FlowLayoutContainer(spacing: 0, centerRows: centered) {
                    phraseSegments(font: font, centered: centered, allowsMultiline: allowsMultiline)
                }
            } else {
                FlowLayout(spacing: 0, centerRows: centered) {
                    phraseSegments(font: font, centered: centered, allowsMultiline: allowsMultiline)
                }
                .frame(maxWidth: .infinity, alignment: centered ? .center : .leading)
            }
        }
        .foregroundStyle(bodyColor ?? theme.inkSoft)
    }

    @ViewBuilder
    private func phraseSegments(font: Font, centered: Bool, allowsMultiline: Bool) -> some View {
        ForEach(LogSymptomsSentenceBuilder.segments(values: values, schema: schema)) { segment in
            if segment.isFilled || segment.step != nil {
                Button {
                    if let target = segment.step {
                        step = target
                    }
                } label: {
                    entryPhraseText(segment.text, font: font, centered: centered, allowsMultiline: allowsMultiline)
                        .fontWeight(segment.isFilled ? .semibold : .regular)
                        .foregroundStyle(segmentColor(for: segment))
                        .underline(
                            segment.step != nil && segment.isFilled,
                            pattern: .dot,
                            color: underlineColor(for: segment)
                        )
                }
                .buttonStyle(.plain)
                .disabled(segment.step == nil)
            } else {
                entryPhraseText(segment.text, font: font, centered: centered, allowsMultiline: allowsMultiline)
                    .foregroundStyle(theme.faint)
            }
        }
    }

    private func entryPhraseText(
        _ text: String,
        font: Font,
        centered: Bool,
        allowsMultiline: Bool
    ) -> some View {
        Text(text)
            .font(font)
            .multilineTextAlignment(centered ? .center : .leading)
            .fixedSize(horizontal: !allowsMultiline, vertical: true)
    }

    private func segmentColor(for segment: SentenceSegment) -> Color {
        if !segment.isFilled { return theme.faint }
        switch segment.accent {
        case .pain: return theme.warmInk
        case .cycle: return theme.coolInk
        }
    }

    private func underlineColor(for segment: SentenceSegment) -> Color {
        switch segment.accent {
        case .pain: return theme.pain
        case .cycle: return theme.cycle
        }
    }

    // MARK: - Step content

    @ViewBuilder
    private var questionBody: some View {
        switch step {
        case .headachePresent:
            headacheStep
        case .severity:
            severityStep
        case .location:
            locationStep
        case .qualityAndMovement:
            qualityStep
        case .relief:
            reliefStep
        case .cycleAndContext:
            cycleContextStep
        case .review:
            EmptyView()
        }
    }

    // MARK: I · Focus steps

    private var headacheStep: some View {
        focusShell(
            title: "Any headache right now?",
            subtitle: "Choose Yes or No to continue."
        ) {
            HStack(spacing: 10) {
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
                SeveritySquareControl(
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
            subtitle: "Select all that apply."
        ) {
            if let field = schema.field(forKey: "location") {
                multiChoiceList(field: field, fieldKey: "location", accent: .pain)
            }
        }
    }

    private var qualityStep: some View {
        focusShell(
            title: "What does it feel like?",
            subtitle: "Pick one or more. Skip if you're not sure."
        ) {
            if let field = schema.field(forKey: "quality") {
                FlowLayout(spacing: 6) {
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
                .frame(maxWidth: .infinity)
            }
        } footer: {
            VStack(alignment: .center, spacing: 8) {
                Text("WORSE WITH MOVEMENT?")
                    .font(.caption2.weight(.semibold))
                    .kerning(1.2)
                    .foregroundStyle(theme.muted)

                HStack(spacing: 10) {
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

    private var reliefStep: some View {
        focusShell(
            title: "Any medication or relief?",
            subtitle: "Select all that apply. Skip if none."
        ) {
            VStack(spacing: 28) {
                if let field = schema.field(forKey: "relief_taken") {
                    multiChoiceList(field: field, fieldKey: "relief_taken", accent: .pain)
                }

                if !selectedChoices("relief_taken").isEmpty,
                   let effectField = schema.field(forKey: "relief_effect") {
                    VStack(alignment: .center, spacing: 8) {
                        Text(effectField.label.uppercased())
                            .font(.caption2.weight(.semibold))
                            .kerning(1.2)
                            .foregroundStyle(theme.muted)

                        FlowLayout(spacing: 6) {
                            ForEach(effectField.values) { option in
                                SelectablePill(
                                    label: option.label,
                                    isSelected: values["relief_effect"] == .choice(option.key),
                                    accent: .pain
                                ) {
                                    if values["relief_effect"] == .choice(option.key) {
                                        values.removeValue(forKey: "relief_effect")
                                    } else {
                                        values["relief_effect"] = .choice(option.key)
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .onAppear { applyMedicationPrefillIfNeeded() }
    }

    private var cycleContextStep: some View {
        focusShell(
            title: "Anything else today?",
            subtitle: "Cycle & triggers — skip what doesn't apply."
        ) {
            VStack(alignment: .center, spacing: 18) {
                if let field = schema.field(forKey: "bleeding") {
                    fieldPills(field: field, accent: .cycle)
                }
                if let field = schema.field(forKey: "cramps_severity"), let range = field.range {
                    Text(field.label.uppercased())
                        .font(.caption2.weight(.semibold))
                        .kerning(1.2)
                        .foregroundStyle(theme.muted)
                    SeveritySquareControl(
                        range: range,
                        labels: field.scaleLabels,
                        selection: scaleBinding(for: field.key),
                        accent: .cycle
                    )
                }
                if let field = schema.field(forKey: "triggers") {
                    fieldPills(field: field, accent: .pain, limit: 4)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var reviewStep: some View {
        let unset = LogSymptomsSentenceBuilder.unsetFieldLabels(values: values, schema: schema)
        let filledRows = LogSymptomsSentenceBuilder.filledDetailRows(values: values, schema: schema)

        return VStack(spacing: 0) {
            Text("Review")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .kerning(1.4)
                .textCase(.uppercase)
                .foregroundStyle(theme.faint)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.bottom, 14)

            entryPhrase(
                font: .system(size: 19, design: .serif),
                centered: true,
                allowsMultiline: true
            )
            .lineSpacing(19 * 0.45)
            .padding(.bottom, filledRows.isEmpty && unset.isEmpty ? 12 : 20)

            if !filledRows.isEmpty {
                reviewDetailCard(rows: filledRows)
                    .padding(.bottom, unset.isEmpty ? 12 : 10)
            }

            if !unset.isEmpty {
                Text(unsetFieldsLine(count: unset.count))
                    .font(.system(size: 12))
                    .foregroundStyle(theme.faint)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 8)
            }

            Text("Tap a word to edit")
                .font(.system(size: 12))
                .foregroundStyle(theme.faint)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }

    private func unsetFieldsLine(count: Int) -> String {
        let noun = count == 1 ? "field" : "fields"
        return "\(count) \(noun) still open · tap a word to fill"
    }

    private func reviewDetailCard(rows: [ReviewDetailRow]) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                if index > 0 {
                    Divider().overlay(theme.line)
                }
                Button {
                    step = row.step
                } label: {
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        Text(row.label)
                            .foregroundStyle(theme.muted)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(row.value)
                            .fontWeight(.semibold)
                            .foregroundStyle(row.accent == .cycle ? theme.coolInk : theme.warmInk)
                            .multilineTextAlignment(.trailing)
                    }
                    .font(.system(size: 13))
                    .padding(.vertical, 9)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
        .guidedReviewDetailCard()
    }

    // MARK: - Focus shell

    private func focusShell<Content: View>(
        title: String,
        subtitle: String?,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .center, spacing: 0) {
            questionTitleBlock(title: title, subtitle: subtitle)
            content()
                .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }

    private func focusShell<Content: View, Footer: View>(
        title: String,
        subtitle: String?,
        @ViewBuilder content: () -> Content,
        @ViewBuilder footer: () -> Footer
    ) -> some View {
        VStack(alignment: .center, spacing: 0) {
            questionTitleBlock(title: title, subtitle: subtitle)
            content()
                .frame(maxWidth: .infinity)
            footer()
                .frame(maxWidth: .infinity)
                .padding(.top, 28)
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }

    private func questionTitleBlock(title: String, subtitle: String?) -> some View {
        VStack(spacing: 0) {
            Text(title)
                .font(.system(size: 24, weight: .medium, design: .serif))
                .multilineTextAlignment(.center)
                .lineSpacing(24 * 0.2)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 6)

            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 12.5))
                    .foregroundStyle(theme.muted)
                    .multilineTextAlignment(.center)
                    .lineSpacing(12.5 * 0.4)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom, 22)
            }
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
                .font(.system(size: 10, design: .monospaced))
                .kerning(0.4)
                .foregroundStyle(theme.faint)
        }
    }

    private var stepNavigationBar: some View {
        VStack(spacing: 0) {
            Divider().overlay(theme.line)
            HStack {
                Button {
                    goBack()
                } label: {
                    Text("← Back")
                        .font(.system(size: 13.5, weight: .medium))
                        .foregroundStyle(theme.muted)
                        .frame(minHeight: 44, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(!canGoBack)
                .opacity(canGoBack ? 1 : 0)
                .accessibilityHidden(!canGoBack)

                Spacer()

                if canSkipCurrentStep {
                    Button {
                        advance()
                    } label: {
                        Text("Skip")
                            .font(.system(size: 13.5, weight: .medium))
                            .foregroundStyle(theme.muted.opacity(0.85))
                            .frame(minHeight: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                Button {
                    advance()
                } label: {
                    Text(nextButtonTitle)
                        .font(.system(size: 13.5, weight: .semibold))
                        .foregroundStyle(canAdvance ? theme.pain : theme.muted)
                        .frame(minHeight: 44, alignment: .trailing)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(!canAdvance)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
        }
        .background(theme.base)
    }

    private var saveBar: some View {
        VStack(spacing: 0) {
            Button(action: onSave) {
                Text("Save entry")
                    .font(.system(size: 14.5, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(theme.text, in: RoundedRectangle(cornerRadius: 16))
                    .foregroundStyle(theme.onPain)
            }
            .buttonStyle(.plain)
            .shadow(color: Color.black.opacity(theme.isLight ? 0.25 : 0), radius: 7, y: 4)
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
        }
        .background(theme.base)
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
        guard let index = step.index(in: activeSteps) else { return false }
        return index > 0
    }

    private var canSkipCurrentStep: Bool {
        step != .headachePresent
    }

    private var canAdvance: Bool {
        switch step {
        case .headachePresent:
            values["migraine_present"] != nil
        default:
            true
        }
    }

    private func bigChoiceButton(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(isSelected ? theme.painDim : theme.paper, in: RoundedRectangle(cornerRadius: 16))
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(isSelected ? Color.clear : theme.line, lineWidth: 1)
                }
                .foregroundStyle(isSelected ? theme.warmInk : theme.inkSoft)
        }
        .buttonStyle(.plain)
    }

    private func fieldPills(field: SchemaField, accent: FieldAccent, limit: Int? = nil) -> some View {
        VStack(alignment: .center, spacing: 6) {
            Text(field.label.uppercased())
                .font(.caption2.weight(.semibold))
                .kerning(1.2)
                .foregroundStyle(accent == .cycle ? theme.cycle : theme.muted)

            FlowLayout(spacing: 6) {
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
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity)
    }

    private func multiChoiceList(field: SchemaField, fieldKey: String, accent: FieldAccent) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(field.values.enumerated()), id: \.element.id) { index, option in
                let isSelected = selectedChoices(fieldKey).contains(option.key)
                Button {
                    toggleChoice(option.key, fieldKey: fieldKey)
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .font(.title3)
                            .foregroundStyle(isSelected ? accent.accentColor(in: theme) : theme.line)

                        Text(option.label)
                            .font(.body.weight(isSelected ? .semibold : .regular))
                            .foregroundStyle(isSelected ? theme.text : theme.muted)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
                .accessibilityLabel(option.label)

                if index < field.values.count - 1 {
                    Divider()
                        .overlay(theme.line)
                        .padding(.leading, 48)
                }
            }
        }
        .background(theme.surface, in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(theme.line, lineWidth: 1)
        }
    }

    private func advance() {
        guard canAdvance else { return }
        guard let index = step.index(in: activeSteps) else { return }
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
        for key in ["severity", "location", "quality", "worse_with_movement", "aura", "relief_taken", "relief_effect"] {
            values.removeValue(forKey: key)
        }
        realignStepIfNeeded()
    }

    /// Keeps the current step valid when the active path shrinks (e.g. migraine → No).
    private func realignStepIfNeeded() {
        guard step.index(in: activeSteps) == nil else { return }
        if let headacheIndex = LogSymptomsFlowStep.headachePresent.index(in: activeSteps) {
            step = activeSteps[headacheIndex]
        } else {
            step = activeSteps.first ?? .headachePresent
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
        if fieldKey == "relief_taken", keys.isEmpty {
            values.removeValue(forKey: "relief_effect")
        }
    }

    private func applyMedicationPrefillIfNeeded() {
        guard !didApplyMedicationPrefill else { return }
        didApplyMedicationPrefill = true

        let allowed = schema.field(forKey: "relief_taken")?.allowedValueKeys ?? []
        let saved = medicationPreferences.savedReliefKeys.filter { allowed.contains($0) }
        guard !saved.isEmpty else { return }

        switch values["relief_taken"] {
        case .none:
            values["relief_taken"] = .choices(saved)
        case .choices(let existing) where existing.isEmpty:
            values["relief_taken"] = .choices(saved)
        default:
            break
        }
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
        onSave: {}
    )
    .environment(\.theme, .softPaper)
    .environment(MedicationPreferences())
}
