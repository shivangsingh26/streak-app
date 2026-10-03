import SwiftUI
import WidgetKit

struct MediumWidgetView: View {
    let summary: Summary

    var body: some View {
        let stats = summary.stats
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(stats.current)")
                        .font(.system(size: 34, weight: .bold, design: .rounded).monospacedDigit())
                        .contentTransition(.numericText())
                    Image(systemName: "flame.fill")
                        .foregroundStyle(stats.current > 0 ? Color.amber : .secondary)
                        .widgetAccentable()
                }
                Text(stats.statusText)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(stats.todayCount > 0 ? Color.emeraldLight : Color.amber)
                Text("\(stats.total) solved")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
                Spacer(minLength: 6)
                Button(intent: LogSolveIntent()) {
                    Label("Solved", systemImage: "plus")
                        .font(.caption.weight(.semibold))
                }
                .buttonStyle(.borderedProminent)
                .tint(.emerald)
                .widgetAccentable()
            }
            Spacer(minLength: 0)
            MiniGrid(summary: summary, weeks: Heatmap.defaultWeeks, cell: 8, gap: 2)
        }
    }
}
