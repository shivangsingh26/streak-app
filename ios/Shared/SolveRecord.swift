import Foundation

/// A read-only, Sendable snapshot of a stored solve. Views and widgets use this,
/// never the SwiftData model, so nothing crosses actor boundaries.
struct SolveRecord: Identifiable, Hashable, Sendable {
    let id: UUID
    let day: Day
    let solvedAt: Date
    let note: String?

    var title: String { Note.split(note).title }
    var pattern: String? { Note.split(note).pattern }
}
