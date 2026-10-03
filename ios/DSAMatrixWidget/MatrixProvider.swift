import OSLog
import WidgetKit

struct MatrixEntry: TimelineEntry {
    let date: Date
    let summary: Summary

    static var placeholder: MatrixEntry {
        let today = Day(Date.now)
        let records = (0..<40).compactMap { offset -> SolveRecord? in
            guard offset % 5 != 3 else { return nil }
            let day = today.adding(days: -offset - 1)
            return SolveRecord(id: UUID(), day: day, solvedAt: day.date(hour: 12), note: "Two Sum | Hash Map")
        }
        return MatrixEntry(date: .now, summary: Summary(records: records, today: today))
    }
}

struct MatrixProvider: TimelineProvider {
    func placeholder(in context: Context) -> MatrixEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (MatrixEntry) -> Void) {
        if context.isPreview {
            completion(.placeholder)
        } else {
            let now = Date.now
            completion(MatrixEntry(date: now, summary: Summary(records: Self.records(), today: Day(now))))
        }
    }

    /// Current entry plus one at the next local midnight, so the widget flips to the
    /// new day (e.g. "At risk") without the app running. `.atEnd` asks again after midnight.
    func getTimeline(in context: Context, completion: @escaping (Timeline<MatrixEntry>) -> Void) {
        let now = Date.now
        let today = Day(now)
        let tomorrow = today.adding(days: 1)
        let records = Self.records()
        let entries = [
            MatrixEntry(date: now, summary: Summary(records: records, today: today)),
            MatrixEntry(date: tomorrow.startDate(), summary: Summary(records: records, today: tomorrow)),
        ]
        completion(Timeline(entries: entries, policy: .atEnd))
    }

    private static func records() -> [SolveRecord] {
        do {
            return try SolveStore().fetchAll()
        } catch {
            Logger.store.error("Widget fetch failed: \(String(describing: error), privacy: .public)")
            return []
        }
    }
}
