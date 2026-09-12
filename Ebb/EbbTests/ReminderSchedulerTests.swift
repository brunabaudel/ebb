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

    @Test func reminderPreferencesDefaultsMatchProductSpec() {
        let preferences = ReminderPreferences(defaults: makeDefaults())
        #expect(!preferences.periodStartNudgeEnabled)
        #expect(preferences.ovulationNudgeEnabled)
        #expect(preferences.lutealNudgeEnabled)
        #expect(!preferences.dailyLogReminderEnabled)
    }

    @Test func reliefAlarmNotificationIDUsesReliefKeyAndWeekday() {
        #expect(ReminderScheduler.reliefAlarmNotificationID(for: "ibuprofen", weekday: 2) == "ebb.relief.alarm.ibuprofen.2")
        #expect(ReminderScheduler.reliefAlarmNotificationID(for: "custom_abc", weekday: 5) == "ebb.relief.alarm.custom_abc.5")
    }

    @Test func reliefAlarmsHonorMigrainePause() {
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

    @Test func reminderPreferencesResetToDefaults() {
        let defaults = makeDefaults()
        let preferences = ReminderPreferences(defaults: defaults)
        preferences.periodStartNudgeEnabled = true
        preferences.ovulationNudgeEnabled = false
        preferences.lutealNudgeEnabled = false
        preferences.dailyLogReminderEnabled = true

        preferences.resetToDefaults()

        #expect(!preferences.periodStartNudgeEnabled)
        #expect(preferences.ovulationNudgeEnabled)
        #expect(preferences.lutealNudgeEnabled)
        #expect(!preferences.dailyLogReminderEnabled)
    }

    private func makeDefaults() -> UserDefaults {
        UserDefaults(suiteName: "ReminderSchedulerTests.\(UUID().uuidString)")!
    }
}

@Suite("Medication preferences")
struct MedicationPreferencesTests {
    let schema = try! SchemaConfig.load(from: .main)

    @Test func savesAndRestoresReliefKeys() {
        let defaults = UserDefaults(suiteName: "MedicationPreferencesTests.\(UUID().uuidString)")!
        let preferences = MedicationPreferences(defaults: defaults)
        preferences.setSaved("ibuprofen", isSaved: true)
        preferences.setSaved("triptan", isSaved: true)
        preferences.setSaved("ibuprofen", isSaved: false)

        let reloaded = MedicationPreferences(defaults: defaults)
        #expect(reloaded.savedReliefKeys == ["triptan"])
    }

    @Test func addsCustomReliefAndSelectsIt() {
        let defaults = UserDefaults(suiteName: "MedicationPreferencesTests.custom.\(UUID().uuidString)")!
        let preferences = MedicationPreferences(defaults: defaults)

        let key = preferences.addCustomRelief(label: "Magnesium", schema: schema)
        #expect(key?.hasPrefix("custom_") == true)
        #expect(preferences.customReliefs.count == 1)
        #expect(preferences.customReliefs.first?.label == "Magnesium")
        #expect(preferences.isSaved(key!))

        let reloaded = MedicationPreferences(defaults: defaults)
        #expect(reloaded.customReliefs == preferences.customReliefs)
        #expect(reloaded.savedReliefKeys == [key!])
    }

    @Test func duplicateLabelSelectsExistingSchemaOption() {
        let defaults = UserDefaults(suiteName: "MedicationPreferencesTests.dup.\(UUID().uuidString)")!
        let preferences = MedicationPreferences(defaults: defaults)

        let key = preferences.addCustomRelief(label: "Ibuprofen", schema: schema)
        #expect(key == "ibuprofen")
        #expect(preferences.customReliefs.isEmpty)
        #expect(preferences.isSaved("ibuprofen"))
    }

    @Test func emptyLabelDoesNotAdd() {
        let defaults = UserDefaults(suiteName: "MedicationPreferencesTests.empty.\(UUID().uuidString)")!
        let preferences = MedicationPreferences(defaults: defaults)

        #expect(preferences.addCustomRelief(label: "   ", schema: schema) == nil)
        #expect(preferences.customReliefs.isEmpty)
    }

    @Test func removeCustomReliefDeletesItFromPreferences() {
        let defaults = UserDefaults(suiteName: "MedicationPreferencesTests.removeCustom.\(UUID().uuidString)")!
        let preferences = MedicationPreferences(defaults: defaults)
        let key = preferences.addCustomRelief(label: "Magnesium", schema: schema)!
        #expect(preferences.isSaved(key))

        preferences.removeRelief(key: key)

        #expect(preferences.customReliefs.isEmpty)
        #expect(!preferences.isSaved(key))
        #expect(ReliefOptions.all(from: schema, customReliefs: preferences.customReliefs).map(\.key).contains(key) == false)

        let reloaded = MedicationPreferences(defaults: defaults)
        #expect(reloaded.customReliefs.isEmpty)
        #expect(reloaded.savedReliefKeys.isEmpty)
    }

    @Test func removeBuiltInSchemaOptionHidesItFromGrid() {
        let defaults = UserDefaults(suiteName: "MedicationPreferencesTests.hideSchema.\(UUID().uuidString)")!
        let preferences = MedicationPreferences(defaults: defaults)
        preferences.setSaved("ibuprofen", isSaved: true)

        preferences.removeRelief(key: "ibuprofen")

        #expect(preferences.hiddenReliefKeys == ["ibuprofen"])
        #expect(!preferences.isSaved("ibuprofen"))
        #expect(
            ReliefOptions.gridOptions(
                from: schema,
                customReliefs: preferences.customReliefs,
                hiddenReliefKeys: preferences.hiddenReliefKeys
            ).map(\.key).contains("ibuprofen") == false
        )
        #expect(ReliefOptions.all(from: schema, customReliefs: preferences.customReliefs).map(\.key).contains("ibuprofen"))

        let reloaded = MedicationPreferences(defaults: defaults)
        #expect(reloaded.hiddenReliefKeys == ["ibuprofen"])
    }

    @Test func storesAndClearsReliefAlarmSchedules() throws {
        let defaults = UserDefaults(suiteName: "MedicationPreferencesTests.alarms.\(UUID().uuidString)")!
        let preferences = MedicationPreferences(defaults: defaults)
        let calendar = Calendar.ebbCalendar
        let start = try #require(calendar.date(from: DateComponents(year: 2026, month: 6, day: 1)))
        let schedule = ReliefAlarmSchedule(
            hour: 8,
            minute: 15,
            weekdays: ReliefAlarmSchedule.weekdayPreset,
            startDate: start,
            endDate: nil
        )

        preferences.setAlarmSchedule(for: "ibuprofen", schedule: schedule)
        #expect(preferences.alarmSchedule(for: "ibuprofen") == schedule)
        #expect(preferences.formattedAlarmTime(for: "ibuprofen")?.isEmpty == false)
        #expect(preferences.formattedAlarmRepeat(for: "ibuprofen") == "Weekdays")
        #expect(preferences.formattedAlarmDuration(for: "ibuprofen") == "Ongoing")

        preferences.clearAlarm(for: "ibuprofen")
        #expect(preferences.alarmSchedule(for: "ibuprofen") == nil)
        #expect(preferences.formattedAlarmTime(for: "ibuprofen") == nil)
        #expect(preferences.formattedAlarmRepeat(for: "ibuprofen") == nil)
        #expect(preferences.formattedAlarmDuration(for: "ibuprofen") == nil)

        let reloaded = MedicationPreferences(defaults: defaults)
        #expect(reloaded.alarmSchedule(for: "ibuprofen") == nil)
    }

    @Test func removeReliefClearsAlarm() throws {
        let defaults = UserDefaults(suiteName: "MedicationPreferencesTests.removeAlarm.\(UUID().uuidString)")!
        let preferences = MedicationPreferences(defaults: defaults)
        let calendar = Calendar.ebbCalendar
        let start = try #require(calendar.date(from: DateComponents(year: 2026, month: 6, day: 1)))
        preferences.setAlarmSchedule(
            for: "ibuprofen",
            schedule: ReliefAlarmSchedule(
                hour: 9,
                minute: 0,
                weekdays: ReliefAlarmSchedule.allWeekdays,
                startDate: start,
                endDate: nil
            )
        )

        preferences.removeRelief(key: "ibuprofen")

        #expect(preferences.alarmSchedule(for: "ibuprofen") == nil)
        #expect(preferences.hiddenReliefKeys == ["ibuprofen"])
    }

    @Test func migratesLegacyDailyAlarmTimes() {
        let defaults = UserDefaults(suiteName: "MedicationPreferencesTests.migrate.\(UUID().uuidString)")!
        let legacy = ["ibuprofen": ReliefAlarmTime(hour: 7, minute: 30)]
        let data = try! JSONEncoder().encode(legacy)
        defaults.set(data, forKey: "ebb.medications.reliefAlarmTimes")

        let preferences = MedicationPreferences(defaults: defaults)
        let schedule = preferences.alarmSchedule(for: "ibuprofen")
        #expect(schedule?.hour == 7)
        #expect(schedule?.minute == 30)
        #expect(schedule?.weekdays == ReliefAlarmSchedule.allWeekdays)
        #expect(schedule?.endDate == nil)
    }

    @Test func reAddingHiddenSchemaOptionUnhidesIt() {
        let defaults = UserDefaults(suiteName: "MedicationPreferencesTests.readdSchema.\(UUID().uuidString)")!
        let preferences = MedicationPreferences(defaults: defaults)
        preferences.removeRelief(key: "ibuprofen")
        #expect(preferences.hiddenReliefKeys == ["ibuprofen"])

        let key = preferences.addCustomRelief(label: "Ibuprofen", schema: schema)
        #expect(key == "ibuprofen")
        #expect(preferences.hiddenReliefKeys.isEmpty)
        #expect(preferences.isSaved("ibuprofen"))
        #expect(preferences.customReliefs.isEmpty)
        #expect(
            ReliefOptions.gridOptions(
                from: schema,
                customReliefs: preferences.customReliefs,
                hiddenReliefKeys: preferences.hiddenReliefKeys
            ).map(\.key).contains("ibuprofen")
        )
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
