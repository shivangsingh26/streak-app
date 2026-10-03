import SwiftUI

struct HeatmapCard: View {
    let popDay: Day?
    let popCount: Int
    let onSelect: (Day) -> Void

    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let cell: CGFloat = 14
    private let gap: CGFloat = 3

    var body: some View {
        let weeks = Heatmap.weeks(endingAt: model.today)
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("Last \(Heatmap.defaultWeeks) weeks").font(.subheadline.weight(.medium))
                Spacer()
                Text("best \(model.stats.longest)d")
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
            }

            HStack(alignment: .top, spacing: 8) {
                weekdayLabels
                ScrollView(.horizontal) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: gap) {
                            ForEach(weeks) { week in
                                Text(week.monthLabel ?? "")
                                    .font(.system(size: 9, design: .monospaced))
                                    .foregroundStyle(.secondary)
                                    .fixedSize()
                                    .frame(width: cell, alignment: .leading)
                            }
                        }
                        HStack(spacing: gap) {
                            ForEach(weeks) { week in
                                VStack(spacing: gap) {
                                    ForEach(week.cells) { cellView($0) }
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                    .padding(.trailing, 4)
                }
                .scrollIndicators(.hidden)
                .defaultScrollAnchor(.trailing)
            }

            HStack(spacing: 4) {
                Text("Tap a day to add or edit").font(.caption).foregroundStyle(.tertiary)
                Spacer()
                Text("less").font(.caption2.monospaced()).foregroundStyle(.tertiary)
                ForEach(0..<4) { HeatCell(level: $0, isToday: false, size: 10) }
                Text("more").font(.caption2.monospaced()).foregroundStyle(.tertiary)
            }
            .accessibilityHidden(true)
        }
        .padding(16)
        .background(Color.surface, in: .rect(cornerRadius: 20))
        .overlay { RoundedRectangle(cornerRadius: 20).strokeBorder(Color.surfaceBorder) }
    }

    private static let weekdayNames = ["", "Mon", "", "Wed", "", "Fri", ""]

    private var weekdayLabels: some View {
        VStack(alignment: .leading, spacing: gap) {
            ForEach(Array(Self.weekdayNames.enumerated()), id: \.offset) { _, name in
                Text(name)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(.tertiary)
                    .frame(height: cell)
            }
        }
        .padding(.top, 4 + 11 + 4) // month row height + spacing
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func cellView(_ cellInfo: HeatmapCell) -> some View {
        if cellInfo.isFuture {
            Color.clear.frame(width: cell, height: cell)
        } else {
            let count = model.count(on: cellInfo.day)
            Button { onSelect(cellInfo.day) } label: {
                HeatCell(level: Heatmap.level(for: count), isToday: cellInfo.isToday, size: cell)
            }
            .buttonStyle(.plain)
            .keyframeAnimator(
                initialValue: 1.0,
                trigger: cellInfo.day == popDay ? popCount : -cellInfo.day.number
            ) { view, scale in
                view.scaleEffect(scale)
            } keyframes: { _ in
                KeyframeTrack {
                    CubicKeyframe(reduceMotion ? 1.0 : 1.25, duration: 0.22)
                    SpringKeyframe(1.0, duration: 0.4, spring: .bouncy)
                }
            }
            .accessibilityLabel("\(cellInfo.day.startDate().formatted(date: .complete, time: .omitted)), \(count) solved")
            .accessibilityIdentifier("day-\(cellInfo.day.key)")
        }
    }
}
