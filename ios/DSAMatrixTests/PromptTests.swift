import Testing
@testable import DSAMatrix

struct PromptTests {
    @Test func freshStart() {
        #expect(Prompt(stats: StreakStats()).title == "One problem. Today.")
    }

    @Test func atRisk() {
        let prompt = Prompt(stats: StreakStats(current: 5, longest: 5, total: 9, todayCount: 0))
        #expect(prompt.title == "Keep the chain alive.")
        #expect(prompt.subtitle.hasPrefix("5-day streak"))
    }

    @Test func solvedToday() {
        #expect(Prompt(stats: StreakStats(current: 1, longest: 1, total: 1, todayCount: 1)).title == "Day one, done.")
        #expect(Prompt(stats: StreakStats(current: 6, longest: 6, total: 8, todayCount: 1)).subtitle == "Day 6 in the books. Rest easy.")
        #expect(Prompt(stats: StreakStats(current: 6, longest: 6, total: 9, todayCount: 2)).subtitle == "2 problems today. Greedy, in the good way.")
    }
}
