import SwiftUI

/// Draws active bursts with simple ballistic physics: exponential drag plus gravity.
struct ParticleLayer: View {
    let system: ParticleSystem

    private let drag = 3.2
    private let gravity = 540.0

    var body: some View {
        TimelineView(.animation(paused: system.bursts.isEmpty)) { timeline in
            Canvas { context, _ in
                for burst in system.bursts {
                    let t = timeline.date.timeIntervalSince(burst.start)
                    guard t >= 0, t < ParticleSystem.lifetime else { continue }
                    let travel = (1 - exp(-drag * t)) / drag
                    let fall = 0.5 * gravity * t * t
                    for particle in burst.particles {
                        var layer = context
                        layer.opacity = 1 - t / ParticleSystem.lifetime
                        layer.translateBy(
                            x: burst.origin.x + particle.velocity.dx * travel,
                            y: burst.origin.y + particle.velocity.dy * travel + fall
                        )
                        layer.rotate(by: .radians(particle.spin * t))
                        let height = particle.isCircle ? particle.size : particle.size * 0.6
                        let rect = CGRect(x: -particle.size / 2, y: -height / 2, width: particle.size, height: height)
                        layer.fill(particle.isCircle ? Path(ellipseIn: rect) : Path(rect), with: .color(particle.color))
                    }
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
