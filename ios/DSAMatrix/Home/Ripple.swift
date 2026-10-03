import SwiftUI

struct Ripple: Identifiable {
    let id = UUID()
    /// Centre in the card's local coordinates.
    let center: CGPoint
    let radius: CGFloat
}

/// Expanding shockwave ring plus a soft radial flash.
struct RippleView: View {
    let ripple: Ripple
    @State private var progress: CGFloat = 0

    var body: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(colors: [Color.emerald.opacity(0.22), .clear], center: .center, startRadius: 0, endRadius: ripple.radius))
                .opacity(1 - progress)
            Circle()
                .strokeBorder(Color.emeraldLight.opacity(0.7), lineWidth: 2)
                .shadow(color: Color.emerald.opacity(0.5), radius: 12)
                .scaleEffect(progress)
                .opacity(1 - progress)
        }
        .frame(width: ripple.radius * 2, height: ripple.radius * 2)
        .position(ripple.center)
        .onAppear {
            withAnimation(.easeOut(duration: 0.7)) { progress = 1 }
        }
    }
}
