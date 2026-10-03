import SwiftUI
import WidgetKit

struct MiniGrid: View {
    let summary: Summary
    let weeks: Int
    let cell: CGFloat
    let gap: CGFloat

    @Environment(\.widgetRenderingMode) private var renderingMode

    var body: some View {
        HStack(spacing: gap) {
            ForEach(Heatmap.weeks(endingAt: summary.today, count: weeks)) { week in
                VStack(spacing: gap) {
                    ForEach(week.cells) { item in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(fill(for: item))
                            .frame(width: cell, height: cell)
                            .overlay {
                                if item.isToday {
                                    RoundedRectangle(cornerRadius: 2.5)
                                        .strokeBorder(Color.white.opacity(0.8), lineWidth: 1)
                                        .padding(-1.5)
                                }
                            }
                    }
                }
            }
        }
        .accessibilityHidden(true)
    }

    private func fill(for item: HeatmapCell) -> Color {
        if item.isFuture { return .clear }
        let level = Heatmap.level(for: summary.counts[item.day] ?? 0)
        if renderingMode == .fullColor { return Color.heat(level) }
        // Tinted / clear / StandBy: brightness carries the level.
        return Color.white.opacity(level == 0 ? 0.15 : 0.35 + Double(level) * 0.2)
    }
}
