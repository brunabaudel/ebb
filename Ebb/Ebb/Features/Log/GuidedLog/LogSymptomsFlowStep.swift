import Foundation

/// Steps in the merged I+L+J+K guided logging flow (new entries only).
enum LogSymptomsFlowStep: Int, CaseIterable, Identifiable, Sendable {
    case headachePresent
    case severity
    case location
    case aura
    case relief
    case triggers
    case cycleAndContext
    case associatedSymptoms
    case review

    var id: Int { rawValue }

    /// Question steps for the guided flow.
    static func questionSteps(hasHeadache: Bool) -> [LogSymptomsFlowStep] {
        if hasHeadache {
            [
                .headachePresent, .location, .aura, .relief, .triggers,
                .cycleAndContext, .associatedSymptoms, .review,
            ]
        } else {
            [.headachePresent, .cycleAndContext, .associatedSymptoms, .review]
        }
    }

    func index(in steps: [LogSymptomsFlowStep]) -> Int? {
        steps.firstIndex(of: self)
    }
}
