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
                sentenceStrip

                progressHeader
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
            }

            GeometryReader { geometry in
                ScrollView {
                    Group {
                        if step == .review {
                            reviewStep
                        } else {
                            questionBody
                        }
                    }
                    .padding(.horizontal, 28)
                    .padding(.vertical, 24)
                    .frame(
                        maxWidth: .infinity,
                        minHeight: geometry.size.height,
                        alignment: step == .review ? .center : .top
                    )
                }
                .scrollIndicators(.hidden)
            }

            if step == .review {
                saveBar
            } else {
                stepNavigationBar
            }
        }
        .background(theme.base)
    }

    // MARK: - Sentence strip (J)

    private var sentenceStrip: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("BUILDING ENTRY · TAP A WORD TO EDIT")
                .font(.caption2.weight(.semibold))
                .kerning(1.2)
                .foregroundStyle(theme.muted)

            entryPhrase(font: .system(.subheadline, design: .serif), centered: false)
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

    private func entryPhrase(font: Font, centered: Bool) -> some View {
        FlowLayout(spacing: 0, centerRows: centered) {
            ForEach(LogSymptomsSentenceBuilder.segments(values: values, schema: schema)) { segment in
                if segment.isFilled || segment.step != nil {
                    Button {
                        if let target = segment.step {
                            step = target
                        }
                    } label: {
                        Text(segment.text)
                            .font(font)
                            .fontWeight(segment.isFilled ? .semibold : .regular)
                            .foregroundStyle(segmentColor(for: segment))
                            .underline(segment.step != nil && segment.isFilled, pattern: .dot)
                    }
                    .buttonStyle(.plain)
                    .disabled(segment.step == nil)
                } else {
                    Text(segment.text)
                        .font(font)
                        .foregroundStyle(theme.muted)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: centered ? .center : .leading)
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
                .frame(maxWidth: .infinity)
            }
        } footer: {
            VStack(alignment: .center, spacing: 8) {
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

    private var reliefStep: some View {
        focusShell(
            title: "Any medication or relief?",
            subtitle: "Select all that apply. Skip if none."
        ) {
            if let field = schema.field(forKey: "relief_taken") {
                multiChoiceList(field: field, fieldKey: "relief_taken", accent: .pain)
            }
        } footer: {
            if !selectedChoices("relief_taken").isEmpty,
               let effectField = schema.field(forKey: "relief_effect") {
                VStack(alignment: .center, spacing: 8) {
                    Text(effectField.label.uppercased())
                        .font(.caption2.weight(.semibold))
                        .kerning(1.2)
                        .foregroundStyle(theme.muted)

                    FlowLayout(spacing: 7) {
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
        .onAppear { applyMedicationPrefillIfNeeded() }
    }

    private var cycleContextStep: some View {
        focusShell(
            title: "Anything else today?",
            subtitle: nil
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
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var reviewStep: some View {
        VStack(alignment: .center, spacing: 24) {
            Spacer(minLength: 12)

            VStack(spacing: 10) {
                Text("TAP A WORD TO EDIT")
                    .font(.caption2.weight(.semibold))
                    .kerning(1.2)
                    .foregroundStyle(theme.muted)

                entryPhrase(font: .system(.title2, design: .serif), centered: true)
            }

            let unset = LogSymptomsSentenceBuilder.unsetFieldLabels(values: values, schema: schema)
            if !unset.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(unset, id: \.label) { item in
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
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(theme.surface, in: RoundedRectangle(cornerRadius: 16))
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(theme.line, lineWidth: 1)
                }
            }

            Spacer(minLength: 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Focus shell

    private func focusShell<Content: View>(
        title: String,
        subtitle: String?,
        @ViewBuilder content: () -> Content
    ) -> some View {
        focusShell(title: title, subtitle: subtitle, content: content) {
            EmptyView()
        }
    }

    private func focusShell<Content: View, Footer: View>(
        title: String,
        subtitle: String?,
        @ViewBuilder content: () -> Content,
        @ViewBuilder footer: () -> Footer
    ) -> some View {
        VStack(spacing: 0) {
            VStack(spacing: 10) {
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
            }

            Spacer(minLength: 36)

            content()
                .frame(maxWidth: .infinity)

            Spacer(minLength: 36)

            footer()
                .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
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
    }

    private var stepNavigationBar: some View {
        VStack(spacing: 0) {
            Divider().overlay(theme.line)
            HStack(spacing: 12) {
                Button {
                    goBack()
                } label: {
                    Text("← Back")
                        .font(.subheadline)
                        .foregroundStyle(theme.muted)
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(!canGoBack)
                .opacity(canGoBack ? 1 : 0)
                .accessibilityHidden(!canGoBack)
                .frame(maxWidth: .infinity)

                if canSkipCurrentStep {
                    Button {
                        advance()
                    } label: {
                        Text("Skip")
                            .font(.subheadline)
                            .foregroundStyle(theme.muted)
                            .frame(width: 64, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                } else {
                    Color.clear
                        .frame(width: 64, height: 44)
                }

                Button {
                    advance()
                } label: {
                    Text(nextButtonTitle)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(canAdvance ? theme.onPain : theme.muted)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(canAdvance ? theme.pain : theme.surface, in: RoundedRectangle(cornerRadius: 12))
                        .overlay {
                            if !canAdvance {
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(theme.line, lineWidth: 1)
                            }
                        }
                }
                .buttonStyle(.plain)
                .disabled(!canAdvance)
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
        }
        .background(theme.base)
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
        VStack(alignment: .center, spacing: 8) {
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
    .environment(\.theme, .plumEmber)
    .environment(MedicationPreferences())
}
