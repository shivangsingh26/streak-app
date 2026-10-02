import SwiftUI

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }

    static let oled = Color(hex: 0x09090B)
    static let surface = Color(hex: 0x18181B)
    static let surfaceBorder = Color.white.opacity(0.08)
    static let zincCell = Color(hex: 0x27272A)
    static let emerald = Color(hex: 0x10B981)
    static let emeraldLight = Color(hex: 0x34D399)
    static let emeraldDark = Color(hex: 0x059669)
    static let mint = Color(hex: 0x6EE7B7)
    static let amber = Color(hex: 0xF59E0B)
    static let flameRed = Color(hex: 0xEF4444)

    /// Heatmap fill for a solve-count level from `Heatmap.level(for:)`.
    static func heat(_ level: Int) -> Color {
        switch level {
        case ...0: .zincCell
        case 1: .emeraldDark.opacity(0.55)
        case 2: .emerald.opacity(0.85)
        default: .emeraldLight
        }
    }
}
