import SwiftUI

/// Medication / relief checklist with per-item effect chips — shared by guided flow and edit form.
struct ReliefTakenControl: View {
    let schema: SchemaConfig
    let takenField: SchemaField
    let effectField: SchemaField
    @Binding var values: [String: FieldValue]

    @Environment(\.theme) private var theme
    @Environment(MedicationPreferences.self) private var medicationPreferences

    private var reliefOptions: [FieldValueOption] {
        ReliefOptions.all(from: schema, customReliefs: medicationPreferences.customReliefs)
    }

    private var extraReliefKeys: Set<String> {
        Set(medicationPreferences.customReliefs.map(\.key))
    }

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(reliefOptions.enumerated()), id: \.element.id) { index, option in
                let isSelected = selectedTakenKeys.contains(option.key)
                VStack(spacing: 0) {
                    Button {
                        ReliefEffects.toggleTakenKey(option.key, in: &values)
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                .font(.title3)
                                .foregroundStyle(isSelected ? FieldAccent.pain.accentColor(in: theme) : theme.line)

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

                    if isSelected {
                        FlowLayout(spacing: 6) {
                            ForEach(effectField.values) { effectOption in
                                ReliefEffectPill(
                                    label: effectOption.label,
                                    effectKey: effectOption.key,
                                    isSelected: reliefEffect(for: option.key) == effectOption.key
                                ) {
                                    ReliefEffects.toggleEffect(
                                        reliefKey: option.key,
                                        effectKey: effectOption.key,
                                        in: &values,
                                        schema: schema,
                                        extraReliefKeys: extraReliefKeys
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 14)
                        .padding(.leading, 34)
                    }
                }

                if index < reliefOptions.count - 1 {
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

    private var selectedTakenKeys: Set<String> {
        Set(ReliefEffects.takenKeys(from: values))
    }

    private func reliefEffect(for reliefKey: String) -> String? {
        ReliefEffects.effect(for: reliefKey, in: values)
    }
}
