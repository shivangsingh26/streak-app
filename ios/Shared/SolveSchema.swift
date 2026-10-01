import Foundation
import SwiftData

enum SchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] { [Solve.self] }

    @Model
    final class Solve {
        #Index<Solve>([\.day])

        var uuid: UUID
        /// "YYYY-MM-DD" — the local day this solve counts for. Fixed at creation;
        /// never re-derived from `solvedAt`, so time-zone changes can't move it.
        var day: String
        var solvedAt: Date
        var note: String?

        init(uuid: UUID = UUID(), day: String, solvedAt: Date, note: String?) {
            self.uuid = uuid
            self.day = day
            self.solvedAt = solvedAt
            self.note = note
        }
    }
}

typealias Solve = SchemaV1.Solve

/// Future schema versions (habits, routines) add a stage here.
enum SolveMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [SchemaV1.self] }
    static var stages: [MigrationStage] { [] }
}
