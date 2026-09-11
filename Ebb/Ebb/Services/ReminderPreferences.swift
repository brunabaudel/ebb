import Foundation
import Observation

/// Local notification toggles and reminder time (build-plan Phase 9).
@Observable
final class ReminderPreferences {
    static let defaultReminderHour = 21
    static let defaultReminderMinute = 0

    var periodStartNudgeEnabled: Bool {
        didSet { defaults.set(periodStartNudgeEnabled, forKey: Keys.periodStartNudge) }
    }

    var ovulationNudgeEnabled: Bool {
        didSet { defaults.set(ovulationNudgeEnabled, forKey: Keys.ovulationNudge) }
    }

    var lutealNudgeEnabled: Bool {
        didSet { defaults.set(lutealNudgeEnabled, forKey: Keys.lutealNudge) }
    }

    var afterPeriodNudgeEnabled: Bool {
        didSet { defaults.set(afterPeriodNudgeEnabled, forKey: Keys.afterPeriodNudge) }
    }

    var fewDaysBeforeNudgeEnabled: Bool {
        didSet { defaults.set(fewDaysBeforeNudgeEnabled, forKey: Keys.fewDaysBeforeNudge) }
    }

    var dailyLogReminderEnabled: Bool {
        didSet { defaults.set(dailyLogReminderEnabled, forKey: Keys.dailyLog) }
    }

    var pauseDuringMigraine: Bool {
        didSet { defaults.set(pauseDuringMigraine, forKey: Keys.pauseDuringMigraine) }
    }

    var reminderHour: Int {
        didSet { persistReminderTime() }
    }

    var reminderMinute: Int {
        didSet { persistReminderTime() }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        periodStartNudgeEnabled = defaults.bool(forKey: Keys.periodStartNudge)
        ovulationNudgeEnabled = defaults.object(forKey: Keys.ovulationNudge) as? Bool ?? true
        lutealNudgeEnabled = defaults.object(forKey: Keys.lutealNudge) as? Bool ?? true
        afterPeriodNudgeEnabled = defaults.bool(forKey: Keys.afterPeriodNudge)
        fewDaysBeforeNudgeEnabled = defaults.object(forKey: Keys.fewDaysBeforeNudge) as? Bool ?? true
        dailyLogReminderEnabled = defaults.bool(forKey: Keys.dailyLog)
        pauseDuringMigraine = defaults.object(forKey: Keys.pauseDuringMigraine) as? Bool ?? true
        reminderHour = defaults.object(forKey: Keys.reminderHour) as? Int ?? Self.defaultReminderHour
        reminderMinute = defaults.object(forKey: Keys.reminderMinute) as? Int ?? Self.defaultReminderMinute
        reminderHour = Self.clampedHour(reminderHour)
        reminderMinute = Self.clampedMinute(reminderMinute)
    }

    var reminderTimeLabel: String {
        String(format: "%02d:%02d", reminderHour, reminderMinute)
    }

    /// Locale-aware time for UI captions (falls back to `reminderTimeLabel`).
    var reminderTimeFormatted: String {
        var components = DateComponents()
        components.hour = reminderHour
        components.minute = reminderMinute
        guard let date = Calendar.current.date(from: components) else {
            return reminderTimeLabel
        }
        return date.formatted(date: .omitted, time: .shortened)
    }

    func resetToDefaults() {
        periodStartNudgeEnabled = false
        ovulationNudgeEnabled = true
        lutealNudgeEnabled = true
        afterPeriodNudgeEnabled = false
        fewDaysBeforeNudgeEnabled = true
        dailyLogReminderEnabled = false
        pauseDuringMigraine = true
        reminderHour = Self.defaultReminderHour
        reminderMinute = Self.defaultReminderMinute
    }

    var hasAnyNudgeEnabled: Bool {
        periodStartNudgeEnabled
            || afterPeriodNudgeEnabled
            || ovulationNudgeEnabled
            || lutealNudgeEnabled
            || fewDaysBeforeNudgeEnabled
            || dailyLogReminderEnabled
    }

    // MARK: - Private

    private enum Keys {
        static let periodStartNudge = "ebb.reminders.periodStartNudge"
        static let ovulationNudge = "ebb.reminders.ovulationNudge"
        static let lutealNudge = "ebb.reminders.lutealNudge"
        static let afterPeriodNudge = "ebb.reminders.afterPeriodNudge"
        static let fewDaysBeforeNudge = "ebb.reminders.fewDaysBeforeNudge"
        static let dailyLog = "ebb.reminders.dailyLog"
        static let pauseDuringMigraine = "ebb.reminders.pauseDuringMigraine"
        static let reminderHour = "ebb.reminders.hour"
        static let reminderMinute = "ebb.reminders.minute"
    }

    private let defaults: UserDefaults

    private func persistReminderTime() {
        let hour = Self.clampedHour(reminderHour)
        let minute = Self.clampedMinute(reminderMinute)
        if reminderHour != hour { reminderHour = hour; return }
        if reminderMinute != minute { reminderMinute = minute; return }
        defaults.set(reminderHour, forKey: Keys.reminderHour)
        defaults.set(reminderMinute, forKey: Keys.reminderMinute)
    }

    private static func clampedHour(_ value: Int) -> Int {
        min(max(value, 0), 23)
    }

    private static func clampedMinute(_ value: Int) -> Int {
        min(max(value, 0), 59)
    }
}
