import OSLog

/// One `SolveStore` (and its `ModelContainer`) per widget extension process, shared by the
/// timeline provider and the "+" intent instead of opening a fresh container on every
/// timeline refresh, snapshot, or tap. `SolveStore` is `Sendable`, so a static let is safe
/// under Swift 6 strict concurrency.
enum WidgetStore {
    static let shared: SolveStore? = {
        do {
            return try SolveStore()
        } catch {
            Logger.store.critical("Widget store failed to open: \(String(describing: error), privacy: .public)")
            return nil
        }
    }()
}
