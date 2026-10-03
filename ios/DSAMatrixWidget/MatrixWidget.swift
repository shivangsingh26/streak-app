import SwiftUI
import WidgetKit

struct MatrixWidgetView: View {
    let entry: MatrixEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .systemMedium: MediumWidgetView(summary: entry.summary)
        case .accessoryCircular: CircularWidgetView(stats: entry.summary.stats)
        case .accessoryRectangular: RectangularWidgetView(summary: entry.summary)
        case .accessoryInline: InlineWidgetView(stats: entry.summary.stats)
        default: SmallWidgetView(summary: entry.summary)
        }
    }
}

struct MatrixWidget: Widget {
    let kind = "MatrixWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MatrixProvider()) { entry in
            MatrixWidgetView(entry: entry)
                .containerBackground(Color.oled, for: .widget)
        }
        .configurationDisplayName("DSA Streak")
        .description("Your streak, today's count and recent activity.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

#Preview(as: .systemMedium) {
    MatrixWidget()
} timeline: {
    MatrixEntry.placeholder
}

#Preview(as: .accessoryCircular) {
    MatrixWidget()
} timeline: {
    MatrixEntry.placeholder
}
