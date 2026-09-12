import Foundation
import Testing
@testable import Ebb

@Suite("Relief alarm scheduling")
struct ReliefAlarmSchedulingTests {
    @Test func isScheduleActiveRespectsStartAndEndDates() throws {
        let calendar = Calendar.ebbCalendar
        let start = try #require(calendar.date(from: DateComponents(year: 2026, month: 6, day: 10)))
        let end = try #require(calendar.date(from: DateComponents(year: 2026, month: 6, day: 20)))
        let beforeStart = try #require(calendar.date(from: DateComponents(year: 2026, month: 6, day: 5)))
        let during = try #require(calendar.date(from: DateComponents(year: 2026, month: 6, day: 15)))
        let afterEnd = try #require(calendar.date(from: DateComponents(year: 2026, month: 6, day: 25)))

        let schedule = ReliefAlarmSchedule(
            hour: 9,
            minute: 0,
            weekdays: ReliefAlarmSchedule.allWeekdays,
            startDate: start,
            endDate: end
        )

        #expect(!ReliefAlarmScheduling.isScheduleActive(schedule, now: beforeStart, calendar: calendar))
        #expect(ReliefAlarmScheduling.isScheduleActive(schedule, now: during, calendar: calendar))
        #expect(!ReliefAlarmScheduling.isScheduleActive(schedule, now: afterEnd, calendar: calendar))
    }

    @Test func shouldScheduleWeekdaySkipsDaysBeforeStart() throws {
        let calendar = Calendar.ebbCalendar
        let start = try #require(calendar.date(from: DateComponents(year: 2026, month: 6, day: 12)))
        let reference = try #require(calendar.date(from: DateComponents(year: 2026, month: 6, day: 10, hour: 12)))
        let schedule = ReliefAlarmSchedule(
            hour: 9,
            minute: 0,
            weekdays: [2],
            startDate: start,
            endDate: nil
        )

        #expect(
            !ReliefAlarmScheduling.shouldScheduleWeekday(
                2,
                in: schedule,
                now: reference,
                calendar: calendar
            )
        )
    }

    @Test func scheduledWeekdaysReturnsOnlyEligibleDays() throws {
        let calendar = Calendar.ebbCalendar
        let start = try #require(calendar.date(from: DateComponents(year: 2026, month: 6, day: 1)))
        let reference = try #require(calendar.date(from: DateComponents(year: 2026, month: 6, day: 5, hour: 12)))
        let schedule = ReliefAlarmSchedule(
            hour: 9,
            minute: 0,
            weekdays: [2, 4, 6],
            startDate: start,
            endDate: nil
        )

        let weekdays = ReliefAlarmScheduling.scheduledWeekdays(
            in: schedule,
            now: reference,
            calendar: calendar
        )
        #expect(weekdays == [2, 4, 6])
    }
}
