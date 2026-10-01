import Testing
@testable import DSAMatrix

struct HeatmapTests {
    private let today = Day(key: "2026-09-30")! // Wednesday
    private var grid: [HeatmapWeek] { Heatmap.weeks(endingAt: today) }

    @Test func sixteenFullSundayFirstWeeksEndingThisWeek() {
        #expect(grid.count == 16)
        #expect(grid.allSatisfy { $0.cells.count == 7 })
        #expect(grid.allSatisfy { $0.cells[0].day.weekday == 0 })
        #expect(grid.last!.cells.contains { $0.day == today })
    }

    @Test func exactlyOneTodayAndOnlyLaterDaysAreFuture() {
        let cells = grid.flatMap(\.cells)
        #expect(cells.filter(\.isToday).map(\.day) == [today])
        #expect(cells.filter(\.isFuture).map(\.day.key) == ["2026-10-01", "2026-10-02", "2026-10-03"])
    }

    @Test func contiguousDays() {
        let numbers = grid.flatMap(\.cells).map(\.day.number)
        #expect(zip(numbers, numbers.dropFirst()).allSatisfy { $1 - $0 == 1 })
    }

    @Test func customWeekCount() {
        #expect(Heatmap.weeks(endingAt: today, count: 5).count == 5)
    }

    @Test func monthLabelsOnlyWhereMonthChanges() {
        let labelled = grid.filter { $0.monthLabel != nil }
        #expect(labelled.count >= 3)
        #expect(labelled.count <= 5)
    }

    @Test func levels() {
        #expect([0, 1, 2, 3, 4, 10, -1].map(Heatmap.level(for:)) == [0, 1, 2, 3, 3, 3, 0])
    }
}
