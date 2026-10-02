import AVFoundation
import OSLog

/// Synthesised micro-chime, no audio files. `.ambient` respects the silent switch
/// and mixes with music instead of pausing it.
@MainActor
final class Chime {
    static let shared = Chime()

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
    private var isConfigured = false
    private lazy var fullBuffer = Self.render(format: format, peak: 0.22, bloom: true)
    private lazy var lightBuffer = Self.render(format: format, peak: 0.12, bloom: false)

    func prepare() {
        do {
            if !isConfigured {
                try AVAudioSession.sharedInstance().setCategory(.ambient)
                engine.attach(player)
                engine.connect(player, to: engine.mainMixerNode, format: format)
                isConfigured = true
            }
            if !engine.isRunning {
                try AVAudioSession.sharedInstance().setActive(true)
                try engine.start()
            }
        } catch {
            Logger.feedback.error("Audio engine failed: \(String(describing: error), privacy: .public)")
        }
    }

    func play(full: Bool) {
        prepare()
        guard engine.isRunning, let buffer = full ? fullBuffer : lightBuffer else { return }
        player.scheduleBuffer(buffer, at: nil, options: .interrupts)
        if !player.isPlaying { player.play() }
    }

    /// Sine C6 (1046.5 Hz) gliding to G6 (1567.98 Hz) over 70 ms, optional G6 bloom at 60 ms,
    /// faint octave partial, 6 ms attack and exponential decay (~250 ms full, ~150 ms light).
    private static func render(format: AVAudioFormat, peak: Float, bloom: Bool) -> AVAudioPCMBuffer? {
        let sampleRate = format.sampleRate
        let decay = bloom ? 0.25 : 0.15
        let frames = AVAudioFrameCount((decay + 0.09) * sampleRate)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames),
              let output = buffer.floatChannelData?[0]
        else { return nil }
        buffer.frameLength = frames

        let c6 = 1046.5, g6 = 1567.98, glide = 0.07, attack = 0.006
        func envelope(_ t: Double) -> Double {
            if t < 0 { return 0 }
            if t < attack { return t / attack }
            return exp(-(t - attack) * 7.6 / decay) // ≈ -66 dB at `decay`
        }

        var primary = 0.0, octave = 0.0, landing = 0.0
        for index in 0..<Int(frames) {
            let t = Double(index) / sampleRate
            let frequency = t < glide ? c6 * pow(g6 / c6, t / glide) : g6
            primary += 2 * .pi * frequency / sampleRate
            octave += 4 * .pi * frequency / sampleRate
            landing += 2 * .pi * g6 / sampleRate
            var sample = sin(primary) * envelope(t) + sin(octave) * envelope(t) * 0.08
            if bloom { sample += sin(landing) * envelope(t - 0.06) * 0.55 }
            output[index] = Float(sample) * peak
        }
        return buffer
    }
}
