import Foundation

/// Inner questions shown one at a time within the first guided-log step.
enum HeadachePresentSubstep: Int, CaseIterable, Identifiable, Sendable {
    case presence
    case severity
    case quality
    case movement

    var id: Int { rawValue }

    /// Maps review / sentence segment ids to the matching inner phase.
    static func from(reviewFieldId id: String) -> HeadachePresentSubstep? {
        switch id {
        case "migraine_present":
            return .presence
        case "severity":
            return .severity
        case "quality", "aura", "associated_symptoms":
            return .quality
        case "worse_with_movement":
            return .movement
        default:
            return nil
        }
    }
}

/// Steps in the merged I+L+J+K guided logging flow (new entries only).
enum LogSymptomsFlowStep: Int, CaseIterable, Identifiable, Sendable {
    case headachePresent
    case severity
    case location
    case relief
    case cycleAndContext
    case review

    var id: Int { rawValue }

    /// Question steps for the guided flow.
    static func questionSteps(hasHeadache: Bool) -> [LogSymptomsFlowStep] {
        if hasHeadache {
            [.headachePresent, .location, .relief, .cycleAndContext, .review]
        } else {
            [.headachePresent, .cycleAndContext, .review]
        }
    }

    func index(in steps: [LogSymptomsFlowStep]) -> Int? {
        steps.firstIndex(of: self)
    }
}
