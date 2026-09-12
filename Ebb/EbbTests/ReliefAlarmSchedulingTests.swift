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

    @Test func formattedRepeatUsesPresetTitlesAndCustomDays() throws {
        let calendar = Self.tileDisplayCalendar
        let start = try #require(calendar.date(from: DateComponents(year: 2026, month: 6, day: 1)))

        let daily = ReliefAlarmSchedule(
            hour: 9,
            minute: 0,
            weekdays: ReliefAlarmSchedule.allWeekdays,
            startDate: start,
            endDate: nil
        )
        #expect(daily.formattedRepeat(calendar: calendar) == "Daily")

        let weekdays = ReliefAlarmSchedule(
            hour: 9,
            minute: 0,
            weekdays: ReliefAlarmSchedule.weekdayPreset,
            startDate: start,
            endDate: nil
        )
        #expect(weekdays.formattedRepeat(calendar: calendar) == "Weekdays")

        let customFew = ReliefAlarmSchedule(
            hour: 9,
            minute: 0,
            weekdays: [2, 4, 6],
            startDate: start,
            endDate: nil
        )
        let expectedFew = [2, 4, 6]
            .map { calendar.shortWeekdaySymbols[$0 - 1] }
            .joined(separator: " ")
        #expect(customFew.formattedRepeat(calendar: calendar) == expectedFew)

        let customMany = ReliefAlarmSchedule(
            hour: 9,
            minute: 0,
            weekdays: [2, 4, 6, 7],
            startDate: start,
            endDate: nil
        )
        let expectedMany = [2, 4, 6, 7].map { weekday in
            let index = (weekday - calendar.firstWeekday + 7) % 7
            return calendar.veryShortWeekdaySymbols[index].uppercased()
        }
        .joined(separator: " ")
        #expect(customMany.formattedRepeat(calendar: calendar) == expectedMany)
    }

    @Test func formattedDurationShowsOngoingOrUntilDate() throws {
        let calendar = Self.tileDisplayCalendar
        let start = try #require(calendar.date(from: DateComponents(year: 2026, month: 6, day: 1)))
        let end = try #require(calendar.date(from: DateComponents(year: 2026, month: 10, day: 12)))

        let ongoing = ReliefAlarmSchedule(
            hour: 9,
            minute: 0,
            weekdays: ReliefAlarmSchedule.allWeekdays,
            startDate: start,
            endDate: nil
        )
        #expect(ongoing.formattedDuration(calendar: calendar) == "Ongoing")

        let bounded = ReliefAlarmSchedule(
            hour: 9,
            minute: 0,
            weekdays: ReliefAlarmSchedule.allWeekdays,
            startDate: start,
            endDate: end
        )
        #expect(bounded.formattedDuration(calendar: calendar) == "Until 12 Oct")
    }

    private static var tileDisplayCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_GB")
        calendar.firstWeekday = 2
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }
}
