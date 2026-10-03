import SwiftUI
import WidgetKit

struct SmallWidgetView: View {
    let summary: Summary

    var body: some View {
        let stats = summary.stats
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
            Spacer(minLength: 4)
            MiniGrid(summary: summary, weeks: 5, cell: 8, gap: 2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(stats.current) day streak. \(stats.statusText)")
    }
}
