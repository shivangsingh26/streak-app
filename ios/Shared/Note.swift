import Foundation

enum Note {
    static let maxLength = 140
    static let defaultTitle = "Problem Solved"

    /// Collapses whitespace, trims, caps length. Blank becomes nil.
    static func normalize(_ raw: String) -> String? {
        let collapsed = raw.split(whereSeparator: \.isWhitespace).joined(separator: " ")
        let capped = String(collapsed.prefix(maxLength)).trimmingCharacters(in: .whitespaces)
        return capped.isEmpty ? nil : capped
    }

    /// "33. Search | Binary Search" → ("33. Search", "Binary Search").
    static func split(_ note: String?) -> (title: String, pattern: String?) {
        guard let note, !note.isEmpty else { return (defaultTitle, nil) }
        guard let bar = note.firstIndex(of: "|") else { return (note, nil) }
        let title = note[..<bar].trimmingCharacters(in: .whitespaces)
        let pattern = note[note.index(after: bar)...].trimmingCharacters(in: .whitespaces)
        return (title.isEmpty ? defaultTitle : title, pattern.isEmpty ? nil : pattern)
    }
}
