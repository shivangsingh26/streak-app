struct Prompt {
    let title: String
    let subtitle: String

    init(stats: StreakStats) {
        if stats.todayCount > 0 {
            title = stats.current > 1 ? "Streak secured." : "Day one, done."
            if stats.todayCount > 1 {
                subtitle = "\(stats.todayCount) problems today. Greedy, in the good way."
            } else if stats.current >= 7 {
                subtitle = "\(stats.current) days of momentum. See you tomorrow."
            } else if stats.current > 1 {
                subtitle = "Day \(stats.current) in the books. Rest easy."
            } else {
                subtitle = "The hardest rep is the first. Come back tomorrow."
            }
        } else if stats.isAtRisk {
            title = "Keep the chain alive."
            subtitle = "\(stats.current)-day streak on the line. One problem is all it takes."
        } else {
            title = "One problem. Today."
            subtitle = "Solve it, then tap. That's the whole ritual."
        }
    }
}
