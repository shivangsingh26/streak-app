import Foundation

/// A local calendar day. Stored and compared as an integer day number
/// (days since 1970-01-01 in the proleptic Gregorian calendar), so DST
/// transitions and time of day can never shift one day into another.
struct Day: Hashable, Comparable, Sendable, Identifiable {
    let number: Int

    var id: Int { number }

    init(number: Int) {
        self.number = number
    }

    /// The calendar day `date` falls on in `calendar`'s time zone.
    init(_ date: Date, calendar: Calendar = .current) {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        self.init(year: parts.year!, month: parts.month!, day: parts.day!)!
    }

    init?(year: Int, month: Int, day: Int) {
        let parts = DateComponents(year: year, month: month, day: day)
        guard parts.isValidDate(in: Self.utc), let date = Self.utc.date(from: parts) else { return nil }
        number = Int((date.timeIntervalSince1970 / 86_400).rounded(.down))
    }

    /// Parses `"YYYY-MM-DD"`.
    init?(key: String) {
        let parts = key.split(separator: "-")
        guard parts.count == 3, parts[0].count == 4, parts[1].count == 2, parts[2].count == 2,
              let year = Int(parts[0]), let month = Int(parts[1]), let day = Int(parts[2])
        else { return nil }
        self.init(year: year, month: month, day: day)
    }

    var key: String {
        let (year, month, day) = components
        return String(format: "%04d-%02d-%02d", year, month, day)
    }

    var components: (year: Int, month: Int, day: Int) {
        let date = Date(timeIntervalSince1970: TimeInterval(number) * 86_400)
        let parts = Self.utc.dateComponents([.year, .month, .day], from: date)
        return (parts.year!, parts.month!, parts.day!)
    }

    /// 0 = Sunday … 6 = Saturday. 1970-01-01 was a Thursday.
    var weekday: Int {
        ((number + 4) % 7 + 7) % 7
    }

    func adding(days: Int) -> Day {
        Day(number: number + days)
    }

    /// The first instant of this day in `calendar`'s time zone.
    func startDate(in calendar: Calendar = .current) -> Date {
        date(hour: 0, in: calendar)
    }

    func date(hour: Int, minute: Int = 0, in calendar: Calendar = .current) -> Date {
        let (year, month, day) = components
        return calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }

    /// Every instant that belongs to this day, for time pickers.
    func timeRange(in calendar: Calendar = .current) -> ClosedRange<Date> {
        startDate(in: calendar)...adding(days: 1).startDate(in: calendar).addingTimeInterval(-1)
    }

    static func < (lhs: Day, rhs: Day) -> Bool {
        lhs.number < rhs.number
    }

    private static let utc: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()
}
