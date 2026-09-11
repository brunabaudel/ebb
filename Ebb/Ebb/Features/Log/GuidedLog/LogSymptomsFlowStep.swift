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
    case review

    var id: Int { rawValue }

    /// Question steps for the guided flow.
    static func questionSteps(hasHeadache: Bool) -> [LogSymptomsFlowStep] {
        if hasHeadache {
            [.headachePresent, .location, .aura, .relief, .triggers, .cycleAndContext, .review]
        } else {
            [.headachePresent, .triggers, .cycleAndContext, .review]
        }
    }

    func index(in steps: [LogSymptomsFlowStep]) -> Int? {
        steps.firstIndex(of: self)
    }
}
