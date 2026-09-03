import Foundation
import Testing
@testable import Ebb

@Suite("ConfirmViewModel")
@MainActor
struct ConfirmViewModelTests {
    let schema = try! SchemaConfig.load(from: .main)

    @Test func classifySuccessAppliesValuesAndHighlights() async {
        let classifier = MockSymptomClassifier(fixedValues: [
            "migraine_present": .boolean(true),
            "severity": .scale(2),
        ])
        let viewModel = ConfirmViewModel(
            transcript: "bad headache",
            schema: schema,
            classifier: classifier
        )

        await viewModel.classifyIfNeeded()

        #expect(viewModel.isClassifying == false)
        #expect(viewModel.classificationFailed == false)
        #expect(viewModel.values["migraine_present"] == .boolean(true))
        #expect(viewModel.values["severity"] == .scale(2))
        #expect(viewModel.aiHighlights["migraine_present"] == ["true"])
        #expect(viewModel.aiHighlights["severity"] == ["2"])
    }

    @Test func emptyTranscriptMarksFailure() async {
        let viewModel = ConfirmViewModel(
            transcript: "   ",
            schema: schema,
            classifier: SynonymSymptomClassifier()
        )

        await viewModel.classifyIfNeeded()

        #expect(viewModel.classificationFailed == true)
        #expect(viewModel.values.isEmpty)
        #expect(viewModel.isClassifying == false)
    }

    @Test func classifierFailureShowsEmptyConfirm() async {
        let classifier = MockSymptomClassifier { _, _ in
            throw SymptomClassifierError.modelUnavailable
        }
        let viewModel = ConfirmViewModel(
            transcript: "headache",
            schema: schema,
            classifier: classifier
        )

        await viewModel.classifyIfNeeded()

        #expect(viewModel.classificationFailed == true)
        #expect(viewModel.values.isEmpty)
    }

    @Test func medicationPrefillWhenReliefEmpty() async {
        let defaults = UserDefaults(suiteName: "ConfirmViewModelTests.meds")!
        defaults.removePersistentDomain(forName: "ConfirmViewModelTests.meds")
        let medicationPreferences = MedicationPreferences(defaults: defaults)
        medicationPreferences.savedReliefKeys = ["ibuprofen"]

        let viewModel = ConfirmViewModel(
            transcript: "feeling rough",
            schema: schema,
            classifier: MockSymptomClassifier(fixedValues: [:]),
            medicationPreferences: medicationPreferences
        )

        await viewModel.classifyIfNeeded()

        #expect(viewModel.values["relief_taken"] == .choices(["ibuprofen"]))
    }

    @Test func medicationPrefillDoesNotOverrideClassifierChoices() async {
        let defaults = UserDefaults(suiteName: "ConfirmViewModelTests.override")!
        defaults.removePersistentDomain(forName: "ConfirmViewModelTests.override")
        let medicationPreferences = MedicationPreferences(defaults: defaults)
        medicationPreferences.savedReliefKeys = ["ibuprofen", "acetaminophen"]

        let viewModel = ConfirmViewModel(
            transcript: "took naproxen",
            schema: schema,
            classifier: MockSymptomClassifier(fixedValues: [
                "relief_taken": .choices(["naproxen"]),
            ]),
            medicationPreferences: medicationPreferences
        )

        await viewModel.classifyIfNeeded()

        #expect(viewModel.values["relief_taken"] == .choices(["naproxen"]))
    }

    @Test func classifyIfNeededRunsOnce() async {
        let callCount = LockedCounter()
        let classifier = MockSymptomClassifier { _, _ in
            callCount.increment()
            return [:]
        }
        let viewModel = ConfirmViewModel(
            transcript: "test",
            schema: schema,
            classifier: classifier
        )

        await viewModel.classifyIfNeeded()
        await viewModel.classifyIfNeeded()

        #expect(callCount.value == 1)
    }
}

private final class LockedCounter: @unchecked Sendable {
    private var count = 0
    private let lock = NSLock()

    var value: Int {
        lock.lock()
        defer { lock.unlock() }
        return count
    }

    func increment() {
        lock.lock()
        defer { lock.unlock() }
        count += 1
    }
}
