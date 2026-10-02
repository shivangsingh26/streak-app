import SwiftUI

/// Confetti bursts in the Home view's "root" coordinate space.
@MainActor
@Observable
final class ParticleSystem {
    struct Particle: Sendable {
        let velocity: CGVector
        let size: Double
        let spin: Double
        let color: Color
        let isCircle: Bool
    }

    struct Burst: Identifiable, Sendable {
        let id = UUID()
        let origin: CGPoint
        let start: Date
        let particles: [Particle]
    }

    static let lifetime = 1.3
    private(set) var bursts: [Burst] = []

    private static let palette: [Color] = [
        .emeraldLight, .emerald, .emeraldDark, .mint, .emeraldLight, .emerald, .amber, .white,
    ]

    func burst(at origin: CGPoint, big: Bool) {
        let particles = (0..<(big ? 110 : 36)).map { index in
            let angle = Double.random(in: 0..<(2 * .pi))
            let speed = Double.random(in: big ? 180...620 : 120...340)
            return Particle(
                velocity: CGVector(dx: cos(angle) * speed, dy: sin(angle) * speed - (big ? 120 : 60)),
                size: .random(in: 3...7),
                spin: .random(in: -12...12),
                color: Self.palette.randomElement()!,
                isCircle: index % 3 == 0
            )
        }
        let burst = Burst(origin: origin, start: .now, particles: particles)
        bursts.append(burst)
        Task {
            try? await Task.sleep(for: .seconds(Self.lifetime))
            bursts.removeAll { $0.id == burst.id }
        }
    }
}
