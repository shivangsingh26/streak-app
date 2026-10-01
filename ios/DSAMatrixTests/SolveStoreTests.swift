import Foundation
import Testing
@testable import DSAMatrix

struct SolveStoreTests {
    private let day = Day(key: "2026-09-30")!

    @Test func addsAndFetchesSortedByTime() throws {
        let store = try SolveStore(inMemory: true)
        try store.add(day: day, at: day.date(hour: 21), note: "LRU Cache")
        try store.add(day: day, at: day.date(hour: 8), note: "  Two   Sum  ")
        let records = try store.fetchAll()
        #expect(records.map(\.note) == ["Two Sum", "LRU Cache"])
        #expect(records.allSatisfy { $0.day == day })
    }

    @Test func blankNoteIsStoredAsNil() throws {
        let store = try SolveStore(inMemory: true)
        let record = try store.add(day: day, at: day.date(hour: 9), note: "   ")
        #expect(record.note == nil)
        #expect(try store.fetchAll().first?.note == nil)
    }

    @Test func updatesNoteAndTime() throws {
        let store = try SolveStore(inMemory: true)
        let record = try store.add(day: day, at: day.date(hour: 9), note: "old")
        try store.update(id: record.id, note: "new | DP", solvedAt: day.date(hour: 10, minute: 30))
        let updated = try #require(try store.fetchAll().first)
        #expect(updated.note == "new | DP")
        #expect(updated.solvedAt == day.date(hour: 10, minute: 30))
        #expect(updated.day == day)
    }

    @Test func deletesOnlyTheTarget() throws {
        let store = try SolveStore(inMemory: true)
        let keep = try store.add(day: day, at: day.date(hour: 9), note: "keep")
        let drop = try store.add(day: day, at: day.date(hour: 10), note: "drop")
        try store.delete(id: drop.id)
        #expect(try store.fetchAll().map(\.id) == [keep.id])
    }

    @Test func missingIDsAreIgnored() throws {
        let store = try SolveStore(inMemory: true)
        try store.update(id: UUID(), note: "x", solvedAt: .now)
        try store.delete(id: UUID())
        #expect(try store.fetchAll().isEmpty)
    }
}
