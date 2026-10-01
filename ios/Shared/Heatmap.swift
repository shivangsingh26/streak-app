import Foundation

struct HeatmapCell: Hashable, Sendable, Identifiable {
    let day: Day
    let isToday: Bool
    let isFuture: Bool

    var id: Int { day.number }
}

struct HeatmapWeek: Hashable, Sendable, Identifiable {
    /// Short month name when a new month starts in this column.
    let monthLabel: String?
    /// Sunday → Saturday.
    let cells: [HeatmapCell]

    var id: Int { cells[0].day.number }
}

enum Heatmap {
    static let defaultWeeks = 16

    /// GitHub-style columns of weeks; the last column is the current week.
    static func weeks(endingAt today: Day, count: Int = defaultWeeks) -> [HeatmapWeek] {
        let lastSaturday = today.adding(days: 6 - today.weekday)
        let firstSunday = lastSaturday.adding(days: -(count * 7 - 1))
        var weeks: [HeatmapWeek] = []
        var previousMonth = -1

        for week in 0..<count {
            let cells = (0..<7).map { offset in
                let day = firstSunday.adding(days: week * 7 + offset)
                return HeatmapCell(day: day, isToday: day == today, isFuture: day > today)
            }
            let first = cells[0].day.components
            var label: String?
            if first.month != previousMonth {
                // Skip a label on the first column when the next month starts within days,
                // so two labels never collide.
                let cramped = week == 0 && first.day > 17
                if !cramped { label = Calendar.current.shortMonthSymbols[first.month - 1] }
                previousMonth = first.month
            }
            weeks.append(HeatmapWeek(monthLabel: label, cells: cells))
        }
        return weeks
    }

    /// 0 = none, 1, 2, 3 = three or more.
    static func level(for count: Int) -> Int {
        min(max(count, 0), 3)
    }
}
