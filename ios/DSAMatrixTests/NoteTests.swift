import Foundation
import Testing
@testable import DSAMatrix

struct NoteTests {
    @Test func normalizesWhitespaceAndBlanks() {
        #expect(Note.normalize("   ") == nil)
        #expect(Note.normalize("") == nil)
        #expect(Note.normalize("  33.  Search |  Binary \n") == "33. Search | Binary")
    }

    @Test func truncatesTo140Characters() {
        let long = String(repeating: "a", count: 200)
        #expect(Note.normalize(long)?.count == 140)
    }

    @Test func splitsTitleAndPattern() {
        #expect(Note.split("33. Search in Rotated Sorted Array | Modified Binary Search")
            == ("33. Search in Rotated Sorted Array", "Modified Binary Search"))
        #expect(Note.split("LRU Cache") == ("LRU Cache", nil))
        #expect(Note.split(nil) == ("Problem Solved", nil))
        #expect(Note.split("| DP") == ("Problem Solved", "DP"))
        #expect(Note.split("Two Sum |") == ("Two Sum", nil))
    }

    @Test func recordExposesTitleAndPattern() {
        let record = SolveRecord(id: UUID(), day: Day(number: 0), solvedAt: .now, note: "Two Sum | Hash Map")
        #expect(record.title == "Two Sum")
        #expect(record.pattern == "Hash Map")
    }
}
