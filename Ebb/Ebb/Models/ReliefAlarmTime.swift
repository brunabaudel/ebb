import Foundation

/// Daily alarm time for one relief option in My care.
struct ReliefAlarmTime: Codable, Equatable, Sendable {
    let hour: Int
    let minute: Int
}
