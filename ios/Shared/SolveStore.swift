import Foundation
import OSLog
import SwiftData

extension Logger {
    static let store = Logger(subsystem: "com.shivangsingh.dsamatrix", category: "store")
}

enum SolveStoreError: LocalizedError {
    case appGroupUnavailable

    var errorDescription: String? {
        "Couldn't open the shared App Group container."
    }
}

/// Thread-safe access to the solve database shared by the app and widget.
/// Every call opens a fresh `ModelContext`, so it always reads what the other
/// process last wrote and no model object ever escapes the call.
final class SolveStore: Sendable {
    static let appGroupID = "group.com.shivangsingh.dsamatrix"

    let container: ModelContainer

    init(inMemory: Bool = false) throws {
        let schema = Schema(versionedSchema: SchemaV1.self)
        let configuration = inMemory
            ? ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            : ModelConfiguration(schema: schema, url: try Self.storeURL())
        container = try ModelContainer(
            for: schema,
            migrationPlan: SolveMigrationPlan.self,
            configurations: [configuration]
        )
    }

    static func storeURL() throws -> URL {
        let fileManager = FileManager.default
        let base: URL
        if let group = fileManager.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) {
            base = group
        } else {
            #if targetEnvironment(simulator)
            // Only when the App Group entitlement is missing (e.g. an unsigned simulator build).
            Logger.store.warning("App Group unavailable; widget will not see app data")
            base = URL.applicationSupportDirectory
            #else
            // On a real device this would silently split the app and widget into separate
            // stores, so fail loudly instead of pretending the data is still shared.
            Logger.store.critical("App Group unavailable on device")
            throw SolveStoreError.appGroupUnavailable
            #endif
        }
        let directory = base.appending(path: "Store", directoryHint: .isDirectory)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appending(path: "DSAMatrix.store")
    }

    func fetchAll() throws -> [SolveRecord] {
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<Solve>(sortBy: [SortDescriptor(\.solvedAt)])
        return try context.fetch(descriptor).compactMap(SolveRecord.init)
    }

    @discardableResult
    func add(day: Day, at date: Date, note: String) throws -> SolveRecord {
        let context = ModelContext(container)
        let solve = Solve(day: day.key, solvedAt: date, note: Note.normalize(note))
        context.insert(solve)
        try context.save()
        return SolveRecord(id: solve.uuid, day: day, solvedAt: date, note: solve.note)
    }

    func update(id: UUID, note: String, solvedAt: Date) throws {
        let context = ModelContext(container)
        guard let solve = try fetch(id, in: context) else { return }
        solve.note = Note.normalize(note)
        solve.solvedAt = solvedAt
        try context.save()
    }

    func delete(id: UUID) throws {
        let context = ModelContext(container)
        guard let solve = try fetch(id, in: context) else { return }
        context.delete(solve)
        try context.save()
    }

    private func fetch(_ id: UUID, in context: ModelContext) throws -> Solve? {
        var descriptor = FetchDescriptor<Solve>(predicate: #Predicate { $0.uuid == id })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }
}

extension SolveRecord {
    /// Nil only for a row with a corrupt day key, which is then skipped.
    init?(_ solve: Solve) {
        guard let day = Day(key: solve.day) else {
            Logger.store.error("Skipping solve with invalid day \(solve.day, privacy: .public)")
            return nil
        }
        self.init(id: solve.uuid, day: day, solvedAt: solve.solvedAt, note: solve.note)
    }
}
