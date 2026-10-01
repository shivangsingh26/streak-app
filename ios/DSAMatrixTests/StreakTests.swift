import Foundation
import Testing
@testable import DSAMatrix

struct StreakTests {
    private let today = Day(key: "2026-09-30")!
    private func back(_ n: Int) -> Day { today.adding(days: -n) }
    private func days(_ list: Day...) -> Set<Day> { Set(list) }

    @Test func emptyIsZero() {
        #expect(Streak.current(days: [], today: today) == 0)
        #expect(Streak.longest(days: []) == 0)
    }

    @Test func countsTodayAndTheRunBeforeIt() {
        #expect(Streak.current(days: days(today, back(1), back(2)), today: today) == 3)
    }

    @Test func openTodayKeepsYesterdaysStreak() {
        #expect(Streak.current(days: days(back(1), back(2), back(3)), today: today) == 3)
    }

    @Test func resetsAfterAFullMissedDay() {
        #expect(Streak.current(days: days(back(2), back(3)), today: today) == 0)
    }

    @Test func stopsAtFirstGap() {
        #expect(Streak.current(days: days(today, back(1), back(3), back(4)), today: today) == 2)
    }

    @Test func spansLeapDayAndYearBoundary() {
        let leap = Day(key: "2024-03-01")!
        #expect(Streak.current(days: days(leap, leap.adding(days: -1), leap.adding(days: -2)), today: leap) == 3)
        let newYear = Day(key: "2026-01-01")!
        #expect(Streak.current(days: days(newYear, newYear.adding(days: -1)), today: newYear) == 2)
    }

    @Test func longestFindsBestHistoricalRun() {
        let set = days(back(20), back(13), back(12), back(11), back(10), back(1), today)
        #expect(Streak.longest(days: set) == 4)
    }

    @Test func multipleSolvesPerDayCountOnceForStreakButAllForTotal() {
        let stats = Streak.stats(counts: [today: 3, back(1): 2, back(5): 1], today: today)
        #expect(stats == StreakStats(current: 2, longest: 2, total: 6, todayCount: 3))
        #expect(!stats.isAtRisk)
    }

    @Test func atRiskWhenTodayEmptyAndStreakAlive() {
        let stats = Streak.stats(counts: [back(1): 1, back(2): 1], today: today)
        #expect(stats.current == 2)
        #expect(stats.todayCount == 0)
        #expect(stats.isAtRisk)
        #expect(stats.statusText == "At risk")
    }

    @Test func zeroCountsAreIgnored() {
        let stats = Streak.stats(counts: [today: 0, back(1): 1], today: today)
        #expect(stats.current == 1)
        #expect(stats.todayCount == 0)
    }

    @Test func statusText() {
        #expect(StreakStats(current: 3, longest: 3, total: 5, todayCount: 2).statusText == "✓ 2 today")
        #expect(StreakStats().statusText == "Solve one today")
    }

    @Test func summaryAggregatesRecords() {
        let records = [
            SolveRecord(id: UUID(), day: back(1), solvedAt: back(1).date(hour: 9), note: "Two Sum | Hash Map"),
            SolveRecord(id: UUID(), day: today, solvedAt: today.date(hour: 8), note: nil),
            SolveRecord(id: UUID(), day: today, solvedAt: today.date(hour: 21), note: "LRU Cache"),
        ]
        let summary = Summary(records: records, today: today)
        #expect(summary.counts == [back(1): 1, today: 2])
        #expect(summary.stats == StreakStats(current: 2, longest: 2, total: 3, todayCount: 2))
        #expect(summary.latestNote == "LRU Cache")
    }
}
