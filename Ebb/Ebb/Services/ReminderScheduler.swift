import Foundation
import UserNotifications

/// Schedules cycle-landmark and daily log local notifications (build-plan Phase 9).
enum ReminderScheduler {
    static let periodStartNotificationID = "ebb.reminder.periodStart"
    static let ovulationNotificationID = "ebb.reminder.ovulation"
    static let lutealNotificationID = "ebb.reminder.luteal"
    static let dailyLogNotificationID = "ebb.reminder.dailyLog"

    private static let notificationIDs = [
        periodStartNotificationID,
        ovulationNotificationID,
        lutealNotificationID,
        dailyLogNotificationID,
    ]

    static let reliefAlarmIDPrefix = "ebb.relief.alarm."

    struct ScheduleInput {
        let preferences: ReminderPreferences
        let overlay: CalendarCycleOverlay
        let entries: [SymptomEntry]
        let now: Date
    }

    struct ReliefAlarmScheduleInput {
        let medicationPreferences: MedicationPreferences
        let schema: SchemaConfig
        let preferences: ReminderPreferences
        let entries: [SymptomEntry]
        let now: Date
    }

    /// Whether reminders should stay quiet while a migraine is active.
    static func shouldPauseReminders(
        entries: [SymptomEntry],
        preferences: ReminderPreferences,
        now: Date = .now,
        calendar: Calendar = .ebbCalendar
    ) -> Bool {
        guard preferences.pauseDuringMigraine else { return false }
        return hasActiveMigraine(entries: entries, now: now, calendar: calendar)
    }

    static func hasActiveMigraine(
        entries: [SymptomEntry],
        now: Date = .now,
        calendar: Calendar = .ebbCalendar
    ) -> Bool {
        let today = calendar.startOfDay(for: now)
        let recent = entries
            .filter { calendar.startOfDay(for: $0.timestamp) == today }
            .filter { $0.fieldValues["migraine_present"] == .boolean(true) }
            .sorted { $0.timestamp > $1.timestamp }

        guard let latest = recent.first else { return false }

        if ReliefEffects.hasFullRelief(in: latest.fieldValues) {
            return false
        }
        return true
    }

    static func nextPeriodNotificationDate(
        overlay: CalendarCycleOverlay,
        from now: Date = .now
    ) -> Date? {
        overlay.nextPeriodNotificationDate(from: now)
    }

    static func nextOvulationNotificationDate(
        overlay: CalendarCycleOverlay,
        from now: Date = .now
    ) -> Date? {
        overlay.nextOvulationDate(from: now)
    }

    static func nextLutealNotificationDate(
        overlay: CalendarCycleOverlay,
        from now: Date = .now
    ) -> Date? {
        overlay.nextLutealStart(from: now)
    }

    @MainActor
    static func reschedule(input: ScheduleInput) async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: notificationIDs)

        guard !shouldPauseReminders(
            entries: input.entries,
            preferences: input.preferences,
            now: input.now
        ) else {
            return
        }

        let calendar = input.overlay.calendar

        if input.preferences.periodStartNudgeEnabled,
           let periodDate = nextPeriodNotificationDate(overlay: input.overlay, from: input.now) {
            await scheduleOneShot(
                center: center,
                identifier: periodStartNotificationID,
                title: "Period may be starting",
                body: "Your estimated period window is beginning. Log if you want it on the calendar.",
                on: periodDate,
                hour: input.preferences.reminderHour,
                minute: input.preferences.reminderMinute,
                calendar: calendar,
                now: input.now
            )
        }

        if input.preferences.ovulationNudgeEnabled,
           let ovulationDate = nextOvulationNotificationDate(overlay: input.overlay, from: input.now) {
            await scheduleOneShot(
                center: center,
                identifier: ovulationNotificationID,
                title: "Estimated ovulation",
                body: "A log today can help you see what this part of the cycle feels like.",
                on: ovulationDate,
                hour: input.preferences.reminderHour,
                minute: input.preferences.reminderMinute,
                calendar: calendar,
                now: input.now
            )
        }

        if input.preferences.lutealNudgeEnabled,
           let lutealDate = nextLutealNotificationDate(overlay: input.overlay, from: input.now) {
            await scheduleOneShot(
                center: center,
                identifier: lutealNotificationID,
                title: "Luteal phase starting",
                body: "Your higher-risk window is beginning. A quick log helps you spot patterns.",
                on: lutealDate,
                hour: input.preferences.reminderHour,
                minute: input.preferences.reminderMinute,
                calendar: calendar,
                now: input.now
            )
        }

        if input.preferences.dailyLogReminderEnabled {
            var components = DateComponents()
            components.hour = input.preferences.reminderHour
            components.minute = input.preferences.reminderMinute

            let content = UNMutableNotificationContent()
            content.title = "Time to log"
            content.body = "A quick check-in keeps your migraine and cycle picture up to date."
            content.sound = .default

            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let request = UNNotificationRequest(
                identifier: dailyLogNotificationID,
                content: content,
                trigger: trigger
            )
            try? await center.add(request)
        }
    }

    static func reliefAlarmNotificationID(for key: String) -> String {
        reliefAlarmIDPrefix + key
    }

    @MainActor
    static func rescheduleReliefAlarms(input: ReliefAlarmScheduleInput) async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        let reliefIdentifiers = pending
            .map(\.identifier)
            .filter { $0.hasPrefix(reliefAlarmIDPrefix) }
        center.removePendingNotificationRequests(withIdentifiers: reliefIdentifiers)

        guard !shouldPauseReminders(
            entries: input.entries,
            preferences: input.preferences,
            now: input.now
        ) else {
            return
        }

        for (key, alarmTime) in input.medicationPreferences.reliefAlarmTimes {
            let label = ReliefOptions.label(
                for: key,
                schema: input.schema,
                customReliefs: input.medicationPreferences.customReliefs
            ) ?? key

            await scheduleDailyReliefAlarm(
                center: center,
                identifier: reliefAlarmNotificationID(for: key),
                label: label,
                hour: alarmTime.hour,
                minute: alarmTime.minute
            )
        }
    }

    static func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    /// Prompts only when the user has never been asked; skips if already granted or denied.
    static func requestAuthorizationIfNeeded() async {
        guard await authorizationStatus() == .notDetermined else { return }
        _ = await requestAuthorization()
    }

    static func authorizationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    // MARK: - Private

    @MainActor
    private static func scheduleOneShot(
        center: UNUserNotificationCenter,
        identifier: String,
        title: String,
        body: String,
        on day: Date,
        hour: Int,
        minute: Int,
        calendar: Calendar,
        now: Date
    ) async {
        let fireComponents = dateComponents(on: day, hour: hour, minute: minute, calendar: calendar)
        guard let fireDate = calendar.date(from: fireComponents), fireDate > now else { return }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: fireComponents, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        try? await center.add(request)
    }

    private static func dateComponents(
        on day: Date,
        hour: Int,
        minute: Int,
        calendar: Calendar
    ) -> DateComponents {
        var components = calendar.dateComponents([.year, .month, .day], from: day)
        components.hour = hour
        components.minute = minute
        return components
    }

    @MainActor
    private static func scheduleDailyReliefAlarm(
        center: UNUserNotificationCenter,
        identifier: String,
        label: String,
        hour: Int,
        minute: Int
    ) async {
        var components = DateComponents()
        components.hour = hour
        components.minute = minute

        let content = UNMutableNotificationContent()
        content.title = "Time for \(label)"
        content.body = "A quick reminder to take your relief."
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        try? await center.add(request)
    }
}
