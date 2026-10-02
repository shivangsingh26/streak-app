import Foundation
import Testing
@testable import DSAMatrix

@MainActor
struct AppModelTests {
    private let noon = Day(key: "2026-09-30")!.date(hour: 12)

    private func makeModel(clock: @escaping () -> Date, reloads: @escaping () -> Void = {}) throws -> AppModel {
        AppModel(store: try SolveStore(inMemory: true), now: clock, reloadWidgets: reloads)
    }

    @Test func firstAndExtraSolvesToday() throws {
        let model = try makeModel(clock: { self.noon })
        #expect(model.stats == StreakStats())

        model.logSolve(note: "Two Sum")
        #expect(model.stats == StreakStats(current: 1, longest: 1, total: 1, todayCount: 1))

        model.logSolve(note: "", at: noon.addingTimeInterval(60))
        #expect(model.stats == StreakStats(current: 1, longest: 1, total: 2, todayCount: 2))
        #expect(model.records(on: model.today).map(\.title) == ["Two Sum", "Problem Solved"])
    }

    @Test func loggingAPastDayExtendsTheStreak() throws {
        let model = try makeModel(clock: { self.noon })
        model.logSolve(note: "today")
        let yesterday = model.today.adding(days: -1)
        model.logSolve(note: "forgot", on: yesterday, at: yesterday.date(hour: 12))
        #expect(model.stats.current == 2)
        #expect(model.count(on: yesterday) == 1)
    }

    @Test func deletingTodaysOnlySolveReturnsToOpenState() throws {
        let model = try makeModel(clock: { self.noon })
        let yesterday = model.today.adding(days: -1)
        model.logSolve(note: "", on: yesterday, at: yesterday.date(hour: 12))
        let record = try #require(model.logSolve(note: "oops"))
        model.delete(record.id)
        #expect(model.stats.todayCount == 0)
        #expect(model.stats.isAtRisk)
        #expect(model.stats.current == 1)
    }

    @Test func updateChangesNoteAndTime() throws {
        let model = try makeModel(clock: { self.noon })
        let record = try #require(model.logSolve(note: "old"))
        let later = model.today.date(hour: 18)
        model.update(record.id, note: "new | Graphs", solvedAt: later)
        let updated = try #require(model.records.first)
        #expect(updated.pattern == "Graphs")
        #expect(updated.solvedAt == later)
    }

    @Test func dayRolloverOnReload() throws {
        var now = noon
        let model = try makeModel(clock: { now })
        model.logSolve(note: "")
        #expect(!model.stats.isAtRisk)

        now = noon.addingTimeInterval(86_400)
        model.reload()
        #expect(model.today == Day(noon).adding(days: 1))
        #expect(model.stats.isAtRisk)
        #expect(model.stats.current == 1)
    }

    @Test func everyChangeReloadsWidgets() throws {
        var reloads = 0
        let model = try makeModel(clock: { self.noon }, reloads: { reloads += 1 })
        let record = try #require(model.logSolve(note: "a"))
        model.update(record.id, note: "b", solvedAt: self.noon)
        model.delete(record.id)
        #expect(reloads == 3)
    }

    @Test func missingStoreShowsErrorInsteadOfCrashing() {
        let model = AppModel(store: nil, now: { self.noon }, reloadWidgets: {})
        #expect(model.errorMessage != nil)
        #expect(model.logSolve(note: "x") == nil)
    }
}
