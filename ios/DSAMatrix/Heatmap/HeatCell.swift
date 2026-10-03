import SwiftUI

struct HeatCell: View {
    let level: Int
    let isToday: Bool
    let size: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(Color.heat(level))
            .overlay {
                if level > 0 {
                    // Inner bevel highlight.
                    RoundedRectangle(cornerRadius: 3).strokeBorder(Color.white.opacity(0.22), lineWidth: 0.5)
                }
            }
            .shadow(color: level >= 3 ? Color.emerald.opacity(0.35) : .clear, radius: 5)
            .frame(width: size, height: size)
            .overlay {
                if isToday {
                    RoundedRectangle(cornerRadius: 4.5)
                        .strokeBorder(Color.white.opacity(0.85), lineWidth: 1.5)
                        .padding(-3)
                }
            }
    }
}
