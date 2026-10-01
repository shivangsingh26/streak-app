import Foundation
import Testing
@testable import DSAMatrix

struct DayTests {
    private func calendar(_ zone: String) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: zone)!
        return calendar
    }

    @Test func keyRoundTrips() {
        let day = Day(key: "2026-09-30")
        #expect(day?.key == "2026-09-30")
        #expect(Day(number: 1).key == "1970-01-02")
    }

    @Test func rejectsInvalidKeys() {
        #expect(Day(key: "2026-02-29") == nil)
        #expect(Day(key: "2026-9-30") == nil)
        #expect(Day(key: "2026-13-01") == nil)
        #expect(Day(key: "hello") == nil)
        #expect(Day(key: "2024-02-29") != nil)
    }

    @Test func addsAcrossMonthAndYearBoundaries() {
        #expect(Day(key: "2026-12-31")!.adding(days: 1).key == "2027-01-01")
        #expect(Day(key: "2026-03-01")!.adding(days: -1).key == "2026-02-28")
        #expect(Day(key: "2024-03-01")!.adding(days: -1).key == "2024-02-29")
    }

    @Test func weekdays() {
        #expect(Day(key: "2026-09-30")!.weekday == 3) // Wednesday
        #expect(Day(key: "2026-09-27")!.weekday == 0) // Sunday
        #expect(Day(key: "1969-12-31")!.weekday == 3) // negative day numbers
    }

    @Test func usesLocalCalendarDay() {
        let tokyo = calendar("Asia/Tokyo")
        let newYork = calendar("America/New_York")
        // 2026-01-05 23:30 UTC is already Jan 6 in Tokyo, still Jan 5 in New York.
        let instant = Date(timeIntervalSince1970: 1_767_655_800)
        #expect(Day(instant, calendar: tokyo).key == "2026-01-06")
        #expect(Day(instant, calendar: newYork).key == "2026-01-05")
    }

    @Test func dstDaysAreOneDayApart() {
        let newYork = calendar("America/New_York")
        let before = Day(key: "2026-03-07")!
        let dst = Day(key: "2026-03-08")! // US DST starts
        #expect(dst.adding(days: -1) == before)
        #expect(Day(dst.startDate(in: newYork), calendar: newYork) == dst)
        #expect(Day(dst.date(hour: 23, minute: 59, in: newYork), calendar: newYork) == dst)
    }

    @Test func timeRangeCoversTheWholeDay() {
        let newYork = calendar("America/New_York")
        let day = Day(key: "2026-09-30")!
        let range = day.timeRange(in: newYork)
        #expect(Day(range.lowerBound, calendar: newYork) == day)
        #expect(Day(range.upperBound, calendar: newYork) == day)
        #expect(Day(range.upperBound.addingTimeInterval(1), calendar: newYork) == day.adding(days: 1))
    }

    @Test func ordering() {
        #expect(Day(key: "2026-09-29")! < Day(key: "2026-09-30")!)
    }
}
