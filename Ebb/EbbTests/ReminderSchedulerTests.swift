import Foundation
import SwiftData
import Testing
@testable import Ebb

@Suite("Reminder scheduler")
struct ReminderSchedulerTests {
    @Test func pausesWhenMigraineLoggedTodayWithoutFullRelief() {
        let preferences = ReminderPreferences(defaults: makeDefaults())
        let entry = SymptomEntry(
            timestamp: .now,
            schemaVersion: "test",
            fieldValues: ["migraine_present": .boolean(true)]
        )
        #expect(
            ReminderScheduler.shouldPauseReminders(
                entries: [entry],
                preferences: preferences
            )
        )
    }

    @Test func doesNotPauseWhenFullReliefLogged() {
        let preferences = ReminderPreferences(defaults: makeDefaults())
        let entry = SymptomEntry(
            timestamp: .now,
            schemaVersion: "test",
            fieldValues: [
                "migraine_present": .boolean(true),
                "relief_effect": .choice("full"),
            ]
        )
        #expect(
            !ReminderScheduler.shouldPauseReminders(
                entries: [entry],
                preferences: preferences
            )
        )
    }

    @Test func nextLutealStartUsesUpcomingCycleDay() throws {
        let calendar = Calendar.ebbCalendar
        let periodStart = try #require(calendar.date(from: DateComponents(year: 2026, month: 6, day: 1)))
        let overlay = CalendarCycleOverlay(
            calendar: calendar,
            cycleLength: 28,
            periodLength: 5,
            anchorPeriodStart: periodStart
        )
        let reference = try #require(calendar.date(from: DateComponents(year: 2026, month: 6, day: 5)))
        let lutealStart = try #require(overlay.nextLutealStart(from: reference))
        let expected = try #require(calendar.date(from: DateComponents(year: 2026, month: 6, day: 15)))
        #expect(calendar.isDate(lutealStart, inSameDayAs: expected))
    }

    @Test func nextLutealStartRollsToNextCycleAfterCurrentWindow() throws {
        let calendar = Calendar.ebbCalendar
        let periodStart = try #require(calendar.date(from: DateComponents(year: 2026, month: 6, day: 1)))
        let overlay = CalendarCycleOverlay(
            calendar: calendar,
            cycleLength: 28,
            periodLength: 5,
            anchorPeriodStart: periodStart
        )
        let reference = try #require(calendar.date(from: DateComponents(year: 2026, month: 6, day: 20)))
        let lutealStart = try #require(overlay.nextLutealStart(from: reference))
        let expected = try #require(calendar.date(from: DateComponents(year: 2026, month: 7, day: 13)))
        #expect(calendar.isDate(lutealStart, inSameDayAs: expected))
    }

    @Test func nextOvulationDateUsesUpcomingCycleDay() throws {
        let calendar = Calendar.ebbCalendar
        let periodStart = try #require(calendar.date(from: DateComponents(year: 2026, month: 6, day: 1)))
        let overlay = CalendarCycleOverlay(
            calendar: calendar,
            cycleLength: 28,
            periodLength: 5,
            anchorPeriodStart: periodStart
        )
        let reference = try #require(calendar.date(from: DateComponents(year: 2026, month: 6, day: 5)))
        let ovulationDate = try #require(overlay.nextOvulationDate(from: reference))
        let expected = try #require(calendar.date(from: DateComponents(year: 2026, month: 6, day: 14)))
        #expect(calendar.isDate(ovulationDate, inSameDayAs: expected))
    }

    @Test func nextOvulationDateRollsToNextCycleAfterCurrentWindow() throws {
        let calendar = Calendar.ebbCalendar
        let periodStart = try #require(calendar.date(from: DateComponents(year: 2026, month: 6, day: 1)))
        let overlay = CalendarCycleOverlay(
            calendar: calendar,
            cycleLength: 28,
            periodLength: 5,
            anchorPeriodStart: periodStart
        )
        let reference = try #require(calendar.date(from: DateComponents(year: 2026, month: 6, day: 20)))
        let ovulationDate = try #require(overlay.nextOvulationDate(from: reference))
        let expected = try #require(calendar.date(from: DateComponents(year: 2026, month: 7, day: 12)))
        #expect(calendar.isDate(ovulationDate, inSameDayAs: expected))
    }

    @Test func nextPeriodNotificationDateUsesCurrentPeriodStartOnDayOne() throws {
        let calendar = Calendar.ebbCalendar
        let periodStart = try #require(calendar.date(from: DateComponents(year: 2026, month: 6, day: 1)))
        let overlay = CalendarCycleOverlay(
            calendar: calendar,
            cycleLength: 28,
            periodLength: 5,
            anchorPeriodStart: periodStart
        )
        let reference = try #require(calendar.date(from: DateComponents(year: 2026, month: 6, day: 1)))
        let nextPeriod = try #require(overlay.nextPeriodNotificationDate(from: reference))
        #expect(calendar.isDate(nextPeriod, inSameDayAs: periodStart))
    }

    @Test func nextPeriodNotificationDateSkipsToNextCycleAfterPeriodBegins() throws {
        let calendar = Calendar.ebbCalendar
        let periodStart = try #require(calendar.date(from: DateComponents(year: 2026, month: 6, day: 1)))
        let overlay = CalendarCycleOverlay(
            calendar: calendar,
            cycleLength: 28,
            periodLength: 5,
            anchorPeriodStart: periodStart
        )
        let reference = try #require(calendar.date(from: DateComponents(year: 2026, month: 6, day: 5)))
        let nextPeriod = try #require(overlay.nextPeriodNotificationDate(from: reference))
        let expected = try #require(calendar.date(from: DateComponents(year: 2026, month: 6, day: 29)))
        #expect(calendar.isDate(nextPeriod, inSameDayAs: expected))
    }

    @Test func nextAfterPeriodDateUsesUpcomingCycleDay() throws {
        let calendar = Calendar.ebbCalendar
        let periodStart = try #require(calendar.date(from: DateComponents(year: 2026, month: 6, day: 1)))
        let overlay = CalendarCycleOverlay(
            calendar: calendar,
            cycleLength: 28,
            periodLength: 5,
            anchorPeriodStart: periodStart
        )
        let reference = try #require(calendar.date(from: DateComponents(year: 2026, month: 6, day: 3)))
        let afterPeriodDate = try #require(overlay.nextAfterPeriodDate(from: reference))
        let expected = try #require(calendar.date(from: DateComponents(year: 2026, month: 6, day: 6)))
        #expect(calendar.isDate(afterPeriodDate, inSameDayAs: expected))
    }

    @Test func nextAfterPeriodDateRollsToNextCycleAfterCurrentWindow() throws {
        let calendar = Calendar.ebbCalendar
        let periodStart = try #require(calendar.date(from: DateComponents(year: 2026, month: 6, day: 1)))
        let overlay = CalendarCycleOverlay(
            calendar: calendar,
            cycleLength: 28,
            periodLength: 5,
            anchorPeriodStart: periodStart
        )
        let reference = try #require(calendar.date(from: DateComponents(year: 2026, month: 6, day: 10)))
        let afterPeriodDate = try #require(overlay.nextAfterPeriodDate(from: reference))
        let expected = try #require(calendar.date(from: DateComponents(year: 2026, month: 7, day: 4)))
        #expect(calendar.isDate(afterPeriodDate, inSameDayAs: expected))
    }

    @Test func nextFewDaysBeforeDateUsesUpcomingCycleDay() throws {
        let calendar = Calendar.ebbCalendar
        let periodStart = try #require(calendar.date(from: DateComponents(year: 2026, month: 6, day: 1)))
        let overlay = CalendarCycleOverlay(
            calendar: calendar,
            cycleLength: 28,
            periodLength: 5,
            anchorPeriodStart: periodStart
        )
        let reference = try #require(calendar.date(from: DateComponents(year: 2026, month: 6, day: 5)))
        let fewDaysBeforeDate = try #require(overlay.nextFewDaysBeforeDate(from: reference))
        let expected = try #require(calendar.date(from: DateComponents(year: 2026, month: 6, day: 27)))
        #expect(calendar.isDate(fewDaysBeforeDate, inSameDayAs: expected))
    }

    @Test func nextFewDaysBeforeDateRollsToNextCycleAfterCurrentWindow() throws {
        let calendar = Calendar.ebbCalendar
        let periodStart = try #require(calendar.date(from: DateComponents(year: 2026, month: 6, day: 1)))
        let overlay = CalendarCycleOverlay(
            calendar: calendar,
            cycleLength: 28,
            periodLength: 5,
            anchorPeriodStart: periodStart
        )
        let reference = try #require(calendar.date(from: DateComponents(year: 2026, month: 6, day: 28)))
        let fewDaysBeforeDate = try #require(overlay.nextFewDaysBeforeDate(from: reference))
        let expected = try #require(calendar.date(from: DateComponents(year: 2026, month: 7, day: 25)))
        #expect(calendar.isDate(fewDaysBeforeDate, inSameDayAs: expected))
    }

    @Test func reminderPreferencesDefaultsMatchProductSpec() {
        let preferences = ReminderPreferences(defaults: makeDefaults())
        #expect(!preferences.periodStartNudgeEnabled)
        #expect(!preferences.afterPeriodNudgeEnabled)
        #expect(preferences.ovulationNudgeEnabled)
        #expect(preferences.lutealNudgeEnabled)
        #expect(preferences.fewDaysBeforeNudgeEnabled)
        #expect(!preferences.dailyLogReminderEnabled)
    }

    @Test func reminderPreferencesResetToDefaults() {
        let defaults = makeDefaults()
        let preferences = ReminderPreferences(defaults: defaults)
        preferences.periodStartNudgeEnabled = true
        preferences.afterPeriodNudgeEnabled = true
        preferences.ovulationNudgeEnabled = false
        preferences.lutealNudgeEnabled = false
        preferences.fewDaysBeforeNudgeEnabled = false
        preferences.dailyLogReminderEnabled = true

        preferences.resetToDefaults()

        #expect(!preferences.periodStartNudgeEnabled)
        #expect(!preferences.afterPeriodNudgeEnabled)
        #expect(preferences.ovulationNudgeEnabled)
        #expect(preferences.lutealNudgeEnabled)
        #expect(preferences.fewDaysBeforeNudgeEnabled)
        #expect(!preferences.dailyLogReminderEnabled)
    }

    private func makeDefaults() -> UserDefaults {
        UserDefaults(suiteName: "ReminderSchedulerTests.\(UUID().uuidString)")!
    }
}

@Suite("Medication preferences")
struct MedicationPreferencesTests {
    @Test func savesAndRestoresReliefKeys() {
        let defaults = UserDefaults(suiteName: "MedicationPreferencesTests.\(UUID().uuidString)")!
        let preferences = MedicationPreferences(defaults: defaults)
        preferences.setSaved("ibuprofen", isSaved: true)
        preferences.setSaved("triptan", isSaved: true)
        preferences.setSaved("ibuprofen", isSaved: false)

        let reloaded = MedicationPreferences(defaults: defaults)
        #expect(reloaded.savedReliefKeys == ["triptan"])
    }
}

@Suite("Onboarding preferences")
struct OnboardingPreferencesTests {
    @Test func marksCompletedInDefaults() {
        let defaults = UserDefaults(suiteName: "OnboardingPreferencesTests.\(UUID().uuidString)")!
        let preferences = OnboardingPreferences(defaults: defaults)
        preferences.markCompleted()
        #expect(defaults.bool(forKey: "ebb.onboarding.completed"))
        let reloaded = OnboardingPreferences(defaults: defaults)
        #expect(reloaded.hasCompletedOnboarding)
    }
}

@Suite("Onboarding view model")
struct OnboardingViewModelTests {
    @Test func stepsExcludeMicAndNotifications() {
        let steps = OnboardingViewModel.Step.allCases
        #expect(steps == [.welcome, .cycleInfo, .healthKit])
    }

    @Test @MainActor func completesAfterFinalStep() {
        let defaults = UserDefaults(suiteName: "OnboardingViewModelTests.\(UUID().uuidString)")!
        let preferences = OnboardingPreferences(defaults: defaults)
        let viewModel = OnboardingViewModel()

        viewModel.advance(from: preferences)
        #expect(viewModel.step == .cycleInfo)
        #expect(!preferences.hasCompletedOnboarding)

        viewModel.advance(from: preferences)
        #expect(viewModel.step == .healthKit)
        #expect(!preferences.hasCompletedOnboarding)

        viewModel.advance(from: preferences)
        #expect(preferences.hasCompletedOnboarding)
    }
}

@Suite("Luteal test data seeder")
struct LutealTestDataSeederTests {
    @Test @MainActor func seedMakesTodayLutealDay15() throws {
        let schema = try SchemaConfig.load()
        let container = try ModelContainer(
            for: SymptomEntry.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext
        let cycleService = CycleService(provider: MockCycleDataProvider(status: .notDetermined))

        let result = try LutealTestDataSeeder.seed(
            schemaVersion: schema.schemaVersion,
            modelContext: context,
            cycleService: cycleService
        )

        #expect(result.cycleDayToday == 15)
        #expect(result.phaseToday == .luteal)
        #expect(Calendar.ebbCalendar.isDate(result.nextLutealStart, inSameDayAs: .now))
    }
}
