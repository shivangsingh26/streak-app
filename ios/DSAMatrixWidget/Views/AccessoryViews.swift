import SwiftUI
import WidgetKit

/// Streak in a ring; the ring is full once today is solved.
struct CircularWidgetView: View {
    let stats: StreakStats

    var body: some View {
        Gauge(value: stats.todayCount > 0 ? 1 : 0) {
            Image(systemName: "flame.fill")
        } currentValueLabel: {
            Text("\(stats.current)").monospacedDigit()
        }
        .gaugeStyle(.accessoryCircularCapacity)
        .widgetAccentable()
        .accessibilityLabel("\(stats.current) day streak. \(stats.statusText)")
    }
}

struct RectangularWidgetView: View {
    let summary: Summary

    var body: some View {
        let stats = summary.stats
        VStack(alignment: .leading, spacing: 2) {
            Text("🔥 \(stats.current)d · \(stats.todayCount) today")
                .font(.headline)
                .widgetAccentable()
            Text(summary.latestNote.map { Note.split($0).title } ?? stats.statusText)
                .font(.caption)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct InlineWidgetView: View {
    let stats: StreakStats

    var body: some View {
        Text("🔥 \(stats.current)d · \(stats.todayCount > 0 ? "✓ today" : stats.isAtRisk ? "at risk" : "solve today")")
    }
}
