import Foundation

/// Cycle decorations for the calendar. Logged bleeding comes from app entries
/// and HealthKit menstrual-flow reads; luteal tint and predicted period
/// windows derive from the most recent period start and user cycle length.
struct CalendarCycleOverlay: Equatable, Sendable {
    let calendar: Calendar
    let cycleLength: Int
    let periodLength: Int
    /// Union of app-logged bleeding days and HealthKit flow days.
    let loggedPeriodDays: Set<Date>
    /// Start of the most recent period cluster (start-of-day).
    let anchorPeriodStart: Date?

    init(
        calendar: Calendar = .ebbCalendar,
        cycleLength: Int = 28,
        periodLength: Int = 5,
        loggedPeriodDays: Set<Date> = [],
        anchorPeriodStart: Date? = nil
    ) {
        self.calendar = calendar
        self.cycleLength = cycleLength
        self.periodLength = periodLength
        self.loggedPeriodDays = loggedPeriodDays
        self.anchorPeriodStart = anchorPeriodStart
    }

    static func build(
        from entries: [SymptomEntry],
        healthKitPeriodDays: Set<Date> = [],
        calendar: Calendar = .ebbCalendar,
        cycleLength: Int = 28,
        periodLength: Int = 5
    ) -> CalendarCycleOverlay {
        let entryDays = Set(
            entries
                .filter(isLoggedBleeding)
                .map { calendar.startOfDay(for: $0.timestamp) }
        )
        let allPeriodDays = entryDays.union(healthKitPeriodDays)
        let anchor = mostRecentPeriodStart(from: allPeriodDays, calendar: calendar)
        return CalendarCycleOverlay(
            calendar: calendar,
            cycleLength: cycleLength,
            periodLength: periodLength,
            loggedPeriodDays: allPeriodDays,
            anchorPeriodStart: anchor
        )
    }

    func cycleDay(for date: Date) -> Int? {
        guard let start = periodStart(for: date) else { return nil }
        let dayOffset = calendar.dateComponents([.day], from: start, to: calendar.startOfDay(for: date)).day ?? 0
        guard dayOffset >= 0 else { return nil }
        return (dayOffset % cycleLength) + 1
    }

    func phase(for date: Date) -> CyclePhase? {
        guard let day = cycleDay(for: date) else { return nil }
        if day <= periodLength { return .menstrual }
        if day <= 13 { return .follicular }
        if day == 14 { return .ovulation }
        return .luteal
    }

    func isLuteal(_ date: Date) -> Bool {
        phase(for: date) == .luteal
    }

    func isLoggedPeriod(_ date: Date) -> Bool {
        loggedPeriodDays.contains(calendar.startOfDay(for: date))
    }

    func isPredictedPeriod(_ date: Date) -> Bool {
        guard anchorPeriodStart != nil else { return false }
        guard !isLoggedPeriod(date) else { return false }
        guard let day = cycleDay(for: date) else { return false }
        return day <= periodLength
    }

    func daysUntilNextPeriod(from date: Date = .now) -> Int? {
        guard let day = cycleDay(for: date) else { return nil }
        if day <= periodLength { return 0 }
        return cycleLength - day + 1
    }

    func migraineCount(in entries: [SymptomEntry], monthContaining date: Date) -> Int {
        entries.filter { entry in
            calendar.isDate(entry.timestamp, equalTo: date, toGranularity: .month)
                && entry.fieldValues["migraine_present"] == .boolean(true)
        }.count
    }

    func entries(on day: Date, from entries: [SymptomEntry]) -> [SymptomEntry] {
        entries
            .filter { calendar.isDate($0.timestamp, inSameDayAs: day) }
            .sorted { $0.timestamp > $1.timestamp }
    }

    /// Start-of-day for the period that contains `date`, if cycle data exists.
    func periodStart(containing date: Date) -> Date? {
        periodStart(for: date)
    }

    /// Entries whose timestamp falls in the same cycle as `date`.
    func entriesInCycle(
        containing date: Date,
        from entries: [SymptomEntry]
    ) -> [SymptomEntry] {
        guard let start = periodStart(for: date),
              let endExclusive = calendar.date(byAdding: .day, value: cycleLength, to: start)
        else { return [] }
        return entries.filter { $0.timestamp >= start && $0.timestamp < endExclusive }
    }

    /// Start-of-day for the next estimated ovulation (cycle day 14).
    func nextOvulationDate(from date: Date = .now) -> Date? {
        guard anchorPeriodStart != nil else { return nil }

        let today = calendar.startOfDay(for: date)
        guard let periodStart = periodStart(containing: date) else { return nil }

        if let currentOvulation = calendar.date(byAdding: .day, value: 13, to: periodStart) {
            let ovulationDay = calendar.startOfDay(for: currentOvulation)
            if ovulationDay >= today {
                return ovulationDay
            }
        }

        guard let nextPeriod = calendar.date(byAdding: .day, value: cycleLength, to: periodStart),
              let nextOvulation = calendar.date(byAdding: .day, value: 13, to: nextPeriod)
        else { return nil }

        return calendar.startOfDay(for: nextOvulation)
    }

    /// Start-of-day for the next period start (cycle day 1) on or after `date`.
    func nextPeriodNotificationDate(from date: Date = .now) -> Date? {
        guard anchorPeriodStart != nil else { return nil }

        let today = calendar.startOfDay(for: date)
        guard let periodStart = periodStart(containing: date) else { return nil }

        let currentPeriodStart = calendar.startOfDay(for: periodStart)
        if currentPeriodStart >= today {
            return currentPeriodStart
        }

        guard let nextPeriod = calendar.date(byAdding: .day, value: cycleLength, to: periodStart)
        else { return nil }

        return calendar.startOfDay(for: nextPeriod)
    }

    /// Start-of-day for the first follicular day after bleeding (cycle day `periodLength + 1`).
    func nextAfterPeriodDate(from date: Date = .now) -> Date? {
        guard anchorPeriodStart != nil else { return nil }

        let today = calendar.startOfDay(for: date)
        guard let periodStart = periodStart(containing: date) else { return nil }

        if let currentAfterPeriod = calendar.date(byAdding: .day, value: periodLength, to: periodStart) {
            let afterPeriodDay = calendar.startOfDay(for: currentAfterPeriod)
            if afterPeriodDay >= today {
                return afterPeriodDay
            }
        }

        guard let nextPeriod = calendar.date(byAdding: .day, value: cycleLength, to: periodStart),
              let nextAfterPeriod = calendar.date(byAdding: .day, value: periodLength, to: nextPeriod)
        else { return nil }

        return calendar.startOfDay(for: nextAfterPeriod)
    }

    /// Start-of-day two days before the next estimated period start.
    func nextFewDaysBeforeDate(from date: Date = .now) -> Date? {
        guard anchorPeriodStart != nil else { return nil }

        let today = calendar.startOfDay(for: date)
        guard let periodStart = periodStart(containing: date) else { return nil }

        guard let nextPeriod = nextPeriodStart(onOrAfter: today, from: periodStart) else { return nil }

        if let fewDaysBefore = calendar.date(byAdding: .day, value: -2, to: nextPeriod) {
            let fewDaysBeforeDay = calendar.startOfDay(for: fewDaysBefore)
            if fewDaysBeforeDay >= today {
                return fewDaysBeforeDay
            }
        }

        guard let followingPeriod = calendar.date(byAdding: .day, value: cycleLength, to: nextPeriod),
              let fewDaysBefore = calendar.date(byAdding: .day, value: -2, to: followingPeriod)
        else { return nil }

        return calendar.startOfDay(for: fewDaysBefore)
    }

    /// Start-of-day for the next luteal-window heads-up (cycle day 15).
    func nextLutealStart(from date: Date = .now) -> Date? {
        guard anchorPeriodStart != nil else { return nil }

        let today = calendar.startOfDay(for: date)
        guard let periodStart = periodStart(containing: date) else { return nil }

        if let currentLuteal = calendar.date(byAdding: .day, value: 14, to: periodStart) {
            let lutealDay = calendar.startOfDay(for: currentLuteal)
            if lutealDay >= today {
                return lutealDay
            }
        }

        guard let nextPeriod = calendar.date(byAdding: .day, value: cycleLength, to: periodStart),
              let nextLuteal = calendar.date(byAdding: .day, value: 14, to: nextPeriod)
        else { return nil }

        return calendar.startOfDay(for: nextLuteal)
    }

    /// Normalized 0…1 positions for the luteal band on a cycle timeline.
    func lutealTimelineRange() -> (start: Double, end: Double) {
        let firstLutealDay = 15
        let span = max(cycleLength - 1, 1)
        let start = Double(firstLutealDay - 1) / Double(span)
        return (min(max(start, 0), 1), 1)
    }

    // MARK: - Private

    private func nextPeriodStart(onOrAfter today: Date, from periodStart: Date) -> Date? {
        let currentPeriodStart = calendar.startOfDay(for: periodStart)
        if currentPeriodStart >= today {
            return currentPeriodStart
        }

        guard let nextPeriod = calendar.date(byAdding: .day, value: cycleLength, to: periodStart)
        else { return nil }

        return calendar.startOfDay(for: nextPeriod)
    }

    private func periodStart(for date: Date) -> Date? {
        guard var start = anchorPeriodStart else { return nil }
        let target = calendar.startOfDay(for: date)

        while let previous = calendar.date(byAdding: .day, value: -cycleLength, to: start),
              previous > target {
            start = previous
        }

        while let next = calendar.date(byAdding: .day, value: cycleLength, to: start),
              next <= target {
            start = next
        }

        return start
    }

    private static func isLoggedBleeding(_ entry: SymptomEntry) -> Bool {
        guard case .choice(let key)? = entry.fieldValues["bleeding"] else { return false }
        return key != "none"
    }

    private static func mostRecentPeriodStart(from days: Set<Date>, calendar: Calendar) -> Date? {
        guard let latest = days.max() else { return nil }
        var start = latest
        while let previous = calendar.date(byAdding: .day, value: -1, to: start),
              days.contains(previous) {
            start = previous
        }
        return start
    }
}
