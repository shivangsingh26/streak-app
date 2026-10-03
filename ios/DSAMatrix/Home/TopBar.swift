import SwiftUI

struct TopBar: View {
    let stats: StreakStats
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "square.grid.3x3.fill")
                .foregroundStyle(Color.emerald)
                .accessibilityHidden(true)
            Text("DSA \(Text("Matrix").foregroundStyle(.secondary))")
                .font(.headline)
            Spacer()
            streakPill
            totalPill
        }
        .frame(height: 52)
    }

    private var streakPill: some View {
        HStack(spacing: 5) {
            Image(systemName: "flame.fill")
                .foregroundStyle(stats.current > 0
                    ? AnyShapeStyle(LinearGradient(colors: [.amber, .flameRed], startPoint: .top, endPoint: .bottom))
                    : AnyShapeStyle(Color(hex: 0x52525B)))
                .symbolEffect(.breathe, isActive: stats.current >= 3 && !reduceMotion)
                .overlay(alignment: .topTrailing) {
                    if stats.isAtRisk {
                        Circle().fill(Color.amber).frame(width: 6, height: 6).offset(x: 3, y: -2)
                    }
                }
            Text("\(stats.current)d")
                .font(.subheadline.monospacedDigit().weight(.semibold))
                .foregroundStyle(stats.current > 0 ? Color.amber : .secondary)
                .contentTransition(.numericText())
        }
        .padding(.horizontal, 12)
        .frame(height: 34)
        .glassEffect()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Current streak \(stats.current) days\(stats.isAtRisk ? ", solve today to keep it" : "")")
    }

    private var totalPill: some View {
        HStack(spacing: 5) {
            Image(systemName: "target").foregroundStyle(Color.emeraldLight)
            Text("\(stats.total)")
                .font(.subheadline.monospacedDigit().weight(.semibold))
                .contentTransition(.numericText())
        }
        .padding(.horizontal, 12)
        .frame(height: 34)
        .glassEffect()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(stats.total) problems solved")
    }
}
