import AppIntents
import WidgetKit

/// The medium widget's "+" button. Runs in the widget process; no haptics, sound or particles.
struct LogSolveIntent: AppIntent {
    static let title: LocalizedStringResource = "Log a Solve"
    static var description: IntentDescription { IntentDescription("Logs a DSA problem solved today.") }

    func perform() async throws -> some IntentResult {
        let now = Date.now
        try SolveStore().add(day: Day(now), at: now, note: "")
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
