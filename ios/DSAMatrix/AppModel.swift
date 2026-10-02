import Foundation
import Observation
import OSLog
import WidgetKit

@MainActor
@Observable
final class AppModel {
    private(set) var records: [SolveRecord] = []
    private(set) var summary: Summary
    private(set) var errorMessage: String?

    @ObservationIgnored private let store: SolveStore?
    @ObservationIgnored private let now: () -> Date
    @ObservationIgnored private let reloadWidgets: () -> Void

    init(
        store: SolveStore?,
        now: @escaping () -> Date = { Date() },
        reloadWidgets: @escaping () -> Void = { WidgetCenter.shared.reloadAllTimelines() }
    ) {
        self.store = store
        self.now = now
        self.reloadWidgets = reloadWidgets
        summary = Summary(records: [], today: Day(now()))
        if store == nil {
            errorMessage = "Couldn't open your data. Nothing was deleted — try reopening the app."
        }
        reload()
    }

    var today: Day { summary.today }
    var stats: StreakStats { summary.stats }

    func count(on day: Day) -> Int {
        summary.counts[day] ?? 0
    }

    func records(on day: Day) -> [SolveRecord] {
        records.filter { $0.day == day }
    }

    /// Re-reads the store (picks up widget writes) and recomputes "today".
    func reload() {
        if let store {
            do {
                records = try store.fetchAll()
            } catch {
                fail("load your history", error)
            }
        }
        recompute()
    }

    @discardableResult
    func logSolve(note: String, on day: Day? = nil, at date: Date? = nil) -> SolveRecord? {
        guard let store else { return nil }
        let date = date ?? now()
        do {
            let record = try store.add(day: day ?? Day(date), at: date, note: note)
            records.append(record)
            records.sort { $0.solvedAt < $1.solvedAt }
            didChange()
            return record
        } catch {
            fail("save", error)
            return nil
        }
    }

    func update(_ id: UUID, note: String, solvedAt: Date) {
        mutate { try $0.update(id: id, note: note, solvedAt: solvedAt) }
    }

    func delete(_ id: UUID) {
        mutate { try $0.delete(id: id) }
    }

    private func mutate(_ change: (SolveStore) throws -> Void) {
        guard let store else { return }
        do {
            try change(store)
            records = try store.fetchAll()
            didChange()
        } catch {
            fail("save", error)
        }
    }

    private func didChange() {
        errorMessage = nil
        recompute()
        reloadWidgets()
    }

    private func recompute() {
        summary = Summary(records: records, today: Day(now()))
    }

    private func fail(_ action: String, _ error: any Error) {
        Logger.store.error("Failed to \(action, privacy: .public): \(String(describing: error), privacy: .public)")
        errorMessage = "Couldn't \(action). \(error.localizedDescription)"
    }
}

#if DEBUG
extension AppModel {
    /// Fills ~15 weeks of varied history for simulator screenshots (`-seed` launch argument).
    func seedDemoHistory() {
        guard let store else { return }
        let notes = ["Two Sum | Hash Map", "LRU Cache | Design", "Course Schedule | Topological Sort", "", "Coin Change | DP"]
        for offset in 1..<105 {
            let wave = sin(Double(offset) * 1.7)
            guard offset <= 5 || wave > -0.2 else { continue }
            let day = today.adding(days: -offset)
            let count = wave > 0.7 ? 3 : wave > 0.3 ? 2 : 1
            for index in 0..<count {
                try? store.add(day: day, at: day.date(hour: 9 + index * 4), note: notes[(offset + index) % notes.count])
            }
        }
        reload()
        reloadWidgets()
    }
}
#endif
