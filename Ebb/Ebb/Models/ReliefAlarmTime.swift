import Foundation

/// Medication reminder schedule for one relief option in My care.
struct ReliefAlarmSchedule: Codable, Equatable, Sendable {
    let hour: Int
    let minute: Int
    /// `Calendar` weekday values (1 = Sunday … 7 = Saturday).
    let weekdays: Set<Int>
    /// First day the schedule is active (day precision).
    let startDate: Date
    /// Last active day, inclusive; `nil` means ongoing.
    let endDate: Date?

    static let allWeekdays: Set<Int> = Set(1...7)
    static let weekdayPreset: Set<Int> = [2, 3, 4, 5, 6]

    init(
        hour: Int,
        minute: Int,
        weekdays: Set<Int>,
        startDate: Date,
        endDate: Date?
    ) {
        self.hour = hour
        self.minute = minute
        self.weekdays = weekdays
        self.startDate = startDate
        self.endDate = endDate
    }

    var repeatPreset: ReliefRepeatPreset {
        if weekdays == Self.allWeekdays { return .daily }
        if weekdays == Self.weekdayPreset { return .weekdays }
        return .custom
    }

    func formattedTime(calendar: Calendar = .current) -> String {
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        guard let date = calendar.date(from: components) else { return "" }
        return date.formatted(date: .omitted, time: .shortened)
    }
}

enum ReliefRepeatPreset: String, CaseIterable, Identifiable {
    case daily
    case weekdays
    case custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .daily: "Daily"
        case .weekdays: "Weekdays"
        case .custom: "Custom"
        }
    }

    func weekdays(calendar: Calendar = .ebbCalendar) -> Set<Int> {
        switch self {
        case .daily:
            ReliefAlarmSchedule.allWeekdays
        case .weekdays:
            ReliefAlarmSchedule.weekdayPreset
        case .custom:
            ReliefAlarmSchedule.weekdayPreset
        }
    }
}

/// Legacy daily-only alarm payload kept for UserDefaults migration.
struct ReliefAlarmTime: Codable, Equatable, Sendable {
    let hour: Int
    let minute: Int
}
