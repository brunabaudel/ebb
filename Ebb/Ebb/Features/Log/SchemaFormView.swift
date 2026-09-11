import SwiftUI

/// Full symptom chart rendered from the bundled schema. Every field and pill
/// comes from `symptom-schema.json`; progressive disclosure follows `appliesWhen`.
struct SchemaFormView: View {
    let schema: SchemaConfig
    @Binding var values: [String: FieldValue]
    var highlightedFields: [String: Set<String>] = [:]

    @Environment(\.theme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            ForEach(visibleFields) { field in
                fieldSection(for: field)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: visibleFieldKeys)
    }

    private var visibleFields: [SchemaField] {
        LogSymptomsFieldOrder.orderedVisibleFields(
            in: schema,
            values: values,
            excludingKeys: LogSymptomsFieldOrder.editExcludedFieldKeys
        )
    }

    private var visibleFieldKeys: [String] {
        visibleFields.map(\.key)
    }

    @ViewBuilder
    private func fieldSection(for field: SchemaField) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: field.label)
            fieldEditor(for: field)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(field.label)
    }

    @ViewBuilder
    private func fieldEditor(for field: SchemaField) -> some View {
        switch field.key {
        case ReliefEffects.takenFieldKey:
            if let effectField = schema.field(forKey: ReliefEffects.legacyEffectFieldKey) {
                ReliefTakenControl(
                    schema: schema,
                    takenField: field,
                    effectField: effectField,
                    values: $values
                )
            }
        default:
            if field.type == .multiEnum,
               LogSymptomsFieldOrder.checklistMultiEnumKeys.contains(field.key) {
                MultiChoiceListControl(
                    field: field,
                    value: binding(for: field.key),
                    accent: field.accent
                )
            } else if usesCardChrome(for: field) {
                FieldControl(
                    field: field,
                    value: binding(for: field.key),
                    highlightedValues: highlightedFields[field.key, default: []],
                    showsLabel: false
                )
                .themeCard(padding: 12)
            } else {
                FieldControl(
                    field: field,
                    value: binding(for: field.key),
                    highlightedValues: highlightedFields[field.key, default: []],
                    showsLabel: false
                )
            }
        }
    }

    private func usesCardChrome(for field: SchemaField) -> Bool {
        switch field.type {
        case .boolean, .scale, .singleEnum, .multiEnum:
            true
        case .stringMap:
            false
        }
    }

    private func binding(for key: String) -> Binding<FieldValue?> {
        Binding(
            get: { values[key] },
            set: { newValue in
                if let newValue {
                    values[key] = newValue
                } else {
                    values.removeValue(forKey: key)
                }
            }
        )
    }
}

#Preview {
    @Previewable @State var values: [String: FieldValue] = [
        "migraine_present": .boolean(true),
        "relief_taken": .choices(["ibuprofen"]),
    ]
    SchemaFormView(schema: try! SchemaConfig.load(), values: $values)
        .padding()
        .background(Theme.softPaper.base)
        .environment(\.theme, .softPaper)
}
