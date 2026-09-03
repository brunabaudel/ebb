import Foundation

/// Steps in the merged I+L+J+K guided logging flow (new entries only).
enum LogSymptomsFlowStep: Int, CaseIterable, Identifiable, Sendable {
    case smartEntry
    case headachePresent
    case severity
    case location
    case qualityAndMovement
    case cycleAndContext
    case review

    var id: Int { rawValue }

    /// Question steps shown after smart entry — excludes smart entry itself.
    static func questionSteps(hasHeadache: Bool) -> [LogSymptomsFlowStep] {
        if hasHeadache {
            [.headachePresent, .severity, .location, .qualityAndMovement, .cycleAndContext, .review]
        } else {
            [.headachePresent, .cycleAndContext, .review]
        }
    }

    func index(in steps: [LogSymptomsFlowStep]) -> Int? {
        steps.firstIndex(of: self)
    }
}
