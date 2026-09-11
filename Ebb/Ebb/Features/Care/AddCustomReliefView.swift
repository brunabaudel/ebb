import SwiftUI

struct AddCustomReliefView: View {
    let schema: SchemaConfig
    @Bindable var medicationPreferences: MedicationPreferences

    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @FocusState private var isNameFocused: Bool

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        Form {
            Section {
                TextField("Name", text: $name)
                    .focused($isNameFocused)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
            } footer: {
                Text("Appears in your medications grid and on the relief screen when logging.")
                    .foregroundStyle(theme.muted)
            }
        }
        .scrollContentBackground(.hidden)
        .themeSettingsScreen()
        .navigationTitle("Add relief")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Add") { save() }
                    .disabled(trimmedName.isEmpty)
            }
        }
        .onAppear {
            isNameFocused = true
        }
    }

    private func save() {
        guard medicationPreferences.addCustomRelief(label: trimmedName, schema: schema) != nil else { return }
        dismiss()
    }
}

#Preview {
    NavigationStack {
        AddCustomReliefView(
            schema: try! SchemaConfig.load(),
            medicationPreferences: MedicationPreferences()
        )
    }
    .environment(\.theme, .softPaper)
}
