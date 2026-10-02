import CoreHaptics
import OSLog

extension Logger {
    static let feedback = Logger(subsystem: "com.shivangsingh.dsamatrix", category: "feedback")
}

/// Taptic Engine patterns. `prepare()` on touch-down so `play` on release has no start-up lag.
@MainActor
final class Haptics {
    enum Kind {
        /// First solve of the day: crisp tap, then a heavier landing (35 ms + 60 ms apart).
        case success
        /// Extra solve the same day.
        case extra
        /// Undo / delete.
        case tick
    }

    static let shared = Haptics()

    private var engine: CHHapticEngine?
    private let isSupported = CHHapticEngine.capabilitiesForHardware().supportsHaptics

    func prepare() {
        guard isSupported else { return }
        do {
            if engine == nil {
                let engine = try CHHapticEngine()
                engine.isAutoShutdownEnabled = true
                engine.resetHandler = {
                    Task { @MainActor in Haptics.shared.restart() }
                }
                self.engine = engine
            }
            try engine?.start()
        } catch {
            Logger.feedback.error("Haptic engine failed: \(String(describing: error), privacy: .public)")
            engine = nil
        }
    }

    func play(_ kind: Kind) {
        prepare()
        guard let engine else { return }
        do {
            let pattern = try CHHapticPattern(events: Self.events(for: kind), parameters: [])
            try engine.makePlayer(with: pattern).start(atTime: CHHapticTimeImmediate)
        } catch {
            Logger.feedback.error("Haptic play failed: \(String(describing: error), privacy: .public)")
        }
    }

    private func restart() {
        try? engine?.start()
    }

    private static func events(for kind: Kind) -> [CHHapticEvent] {
        func tap(at time: TimeInterval, intensity: Float, sharpness: Float) -> CHHapticEvent {
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness),
                ],
                relativeTime: time
            )
        }
        switch kind {
        case .success:
            return [tap(at: 0, intensity: 0.75, sharpness: 0.9), tap(at: 0.095, intensity: 1, sharpness: 0.55)]
        case .extra:
            return [tap(at: 0, intensity: 0.6, sharpness: 0.75)]
        case .tick:
            return [tap(at: 0, intensity: 0.35, sharpness: 0.5)]
        }
    }
}
