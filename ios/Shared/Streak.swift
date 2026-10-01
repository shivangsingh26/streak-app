import Foundation

struct StreakStats: Equatable, Sendable {
    var current = 0
    var longest = 0
    var total = 0
    var todayCount = 0

    /// Today has no solve yet but yesterday's run is alive.
    var isAtRisk: Bool { todayCount == 0 && current > 0 }

    var statusText: String {
        if todayCount > 0 { return "✓ \(todayCount) today" }
        return isAtRisk ? "At risk" : "Solve one today"
    }
}

enum Streak {
    static func stats(counts: [Day: Int], today: Day) -> StreakStats {
        let days = Set(counts.filter { $0.value > 0 }.keys)
        let current = current(days: days, today: today)
        return StreakStats(
            current: current,
            longest: max(longest(days: days), current),
            total: counts.values.reduce(0, +),
            todayCount: counts[today] ?? 0
        )
    }

    /// Run of consecutive days ending today — or ending yesterday while today is still open.
    static func current(days: Set<Day>, today: Day) -> Int {
        var cursor = days.contains(today) ? today : today.adding(days: -1)
        var count = 0
        while days.contains(cursor) {
            count += 1
            cursor = cursor.adding(days: -1)
        }
        return count
    }

    static func longest(days: Set<Day>) -> Int {
        var longest = 0
        var run = 0
        var previous: Int?
        for number in days.map(\.number).sorted() {
            run = previous.map { number == $0 + 1 } == true ? run + 1 : 1
            longest = max(longest, run)
            previous = number
        }
        return longest
    }
}
