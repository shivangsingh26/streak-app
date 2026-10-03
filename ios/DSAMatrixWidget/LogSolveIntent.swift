import AppIntents
import WidgetKit

enum LogSolveIntentError: LocalizedError {
    case storeUnavailable

    var errorDescription: String? {
        "Couldn't reach the solve store. Open DSA Matrix to try again."
    }
}

/// The medium widget's "+" button. Runs in the widget process; no haptics, sound or particles.
struct LogSolveIntent: AppIntent {
    static let title: LocalizedStringResource = "Log a Solve"
    static var description: IntentDescription { IntentDescription("Logs a DSA problem solved today.") }

    func perform() async throws -> some IntentResult {
        guard let store = WidgetStore.shared else {
            throw LogSolveIntentError.storeUnavailable
        }
        let now = Date.now
        try store.add(day: Day(now), at: now, note: "")
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
