import Foundation

/// Everything the UI and widgets derive from the solve history.
struct Summary: Equatable, Sendable {
    let today: Day
    let counts: [Day: Int]
    let stats: StreakStats
    let latestNote: String?

    init(records: [SolveRecord], today: Day) {
        var counts: [Day: Int] = [:]
        for record in records {
            counts[record.day, default: 0] += 1
        }
        self.today = today
        self.counts = counts
        stats = Streak.stats(counts: counts, today: today)
        latestNote = records.max { $0.solvedAt < $1.solvedAt }?.note
    }
}
