import Foundation

enum ReliefAlarmScheduling {
    static func isScheduleActive(
        _ schedule: ReliefAlarmSchedule,
        now: Date = .now,
        calendar: Calendar = .ebbCalendar
    ) -> Bool {
        let today = calendar.startOfDay(for: now)
        let start = calendar.startOfDay(for: schedule.startDate)
        guard today >= start else { return false }
        if let endDate = schedule.endDate {
            return today <= calendar.startOfDay(for: endDate)
        }
        return true
    }

    static func nextFireDate(
        weekday: Int,
        hour: Int,
        minute: Int,
        after now: Date,
        calendar: Calendar = .ebbCalendar
    ) -> Date? {
        var components = DateComponents()
        components.weekday = weekday
        components.hour = hour
        components.minute = minute
        return calendar.nextDate(
            after: now,
            matching: components,
            matchingPolicy: .nextTime,
            direction: .forward
        )
    }

    static func shouldScheduleWeekday(
        _ weekday: Int,
        in schedule: ReliefAlarmSchedule,
        now: Date = .now,
        calendar: Calendar = .ebbCalendar
    ) -> Bool {
        guard schedule.weekdays.contains(weekday) else { return false }
        guard let nextFire = nextFireDate(
            weekday: weekday,
            hour: schedule.hour,
            minute: schedule.minute,
            after: now,
            calendar: calendar
        ) else {
            return false
        }

        let nextDay = calendar.startOfDay(for: nextFire)
        let start = calendar.startOfDay(for: schedule.startDate)
        guard nextDay >= start else { return false }

        if let endDate = schedule.endDate {
            return nextDay <= calendar.startOfDay(for: endDate)
        }
        return true
    }

    static func scheduledWeekdays(
        in schedule: ReliefAlarmSchedule,
        now: Date = .now,
        calendar: Calendar = .ebbCalendar
    ) -> [Int] {
        schedule.weekdays
            .sorted()
            .filter { shouldScheduleWeekday($0, in: schedule, now: now, calendar: calendar) }
    }
}
