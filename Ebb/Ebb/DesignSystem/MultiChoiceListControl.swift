import SwiftUI

/// Checkmark list for multi-select schema fields — shared by guided flow and edit form.
struct MultiChoiceListControl: View {
    let field: SchemaField
    @Binding var value: FieldValue?
    var accent: FieldAccent = .pain

    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(field.values.enumerated()), id: \.element.id) { index, option in
                let isSelected = selectedChoices.contains(option.key)
                Button {
                    toggleChoice(option.key)
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
        .background(theme.surface, in: RoundedRectangle(cornerRadius: theme.cardCornerRadius))
        .overlay {
            RoundedRectangle(cornerRadius: theme.cardCornerRadius)
                .strokeBorder(theme.line, lineWidth: 1)
        }
        .shadow(
            color: theme.cardShadowColor,
            radius: theme.cardShadowRadius,
            y: theme.cardShadowY
        )
    }

    private var selectedChoices: Set<String> {
        Set(orderedChoices)
    }

    private var orderedChoices: [String] {
        if case .choices(let keys)? = value { return keys }
        return []
    }

    private func toggleChoice(_ key: String) {
        if field.key == AuraChoices.fieldKey {
            if let updated = AuraChoices.toggle(in: orderedChoices, optionKey: key) {
                value = .choices(updated)
            } else {
                value = nil
            }
            return
        }

        var choices = orderedChoices
        if let index = choices.firstIndex(of: key) {
            choices.remove(at: index)
        } else {
            choices.append(key)
        }
        value = choices.isEmpty ? nil : .choices(choices)
    }
}
