import SwiftUI

struct ButtonFace: View {
    let solved: Bool
    let count: Int

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark")
                .font(.system(size: solved ? 52 : 46, weight: solved ? .semibold : .light))
                .foregroundStyle(solved ? Color.emeraldLight : Color(hex: 0x71717A))
                .contentTransition(.symbolEffect(.replace))
            VStack(spacing: 3) {
                Text(solved ? "\(count) SOLVED TODAY" : "TAP WHEN SOLVED")
                if solved { Text("TAP TO ADD").foregroundStyle(Color(hex: 0x71717A)) }
            }
            .font(.caption2.monospaced())
            .tracking(1.5)
            .foregroundStyle(solved ? Color.emerald : Color(hex: 0xA1A1AA))
        }
        .frame(width: 168, height: 168)
        .background {
            if solved {
                Circle().fill(Color.surface)
            } else {
                Circle().fill(RadialGradient(
                    colors: [Color(hex: 0x1F2B27), .surface, Color(hex: 0x111113)],
                    center: UnitPoint(x: 0.5, y: 0.3), startRadius: 0, endRadius: 100
                ))
            }
        }
        .overlay {
            Circle().strokeBorder(solved ? Color.emerald.opacity(0.3) : Color.emeraldLight.opacity(0.35), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.8), radius: 20, y: 14)
        .contentShape(.circle)
    }
}
