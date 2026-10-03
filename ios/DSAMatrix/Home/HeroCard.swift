import SwiftUI

struct HeroCard: View {
    /// Called on every solve with the raw note and the touch point in "root" space.
    let onSolve: (_ note: String, _ location: CGPoint) -> Void

    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var note = ""
    @State private var lastTouch: CGPoint?
    @State private var buttonFrame = CGRect.zero
    @State private var cardFrame = CGRect.zero
    @State private var ripples: [Ripple] = []
    @FocusState private var noteFocused: Bool

    private var todayCount: Int { model.stats.todayCount }
    private var solved: Bool { todayCount > 0 }

    var body: some View {
        let prompt = Prompt(stats: model.stats)
        VStack(spacing: 0) {
            Text(model.today.startDate().formatted(.dateTime.weekday(.wide).month(.abbreviated).day()).uppercased())
                .font(.caption.monospaced())
                .tracking(1.5)
                .foregroundStyle(.secondary)

            VStack(spacing: 6) {
                Text(prompt.title)
                    .font(.title2.weight(.semibold))
                Text(prompt.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 8)
            .id(prompt.title)
            .transition(.opacity)

            solveButton
                .padding(.vertical, 28)

            noteField

            if solved {
                VStack(spacing: 12) {
                    ForEach(model.records(on: model.today)) { SolveRow(record: $0) }
                }
                .padding(.top, 16)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Color.surface, in: .rect(cornerRadius: 28))
        .overlay {
            ZStack { ForEach(ripples) { RippleView(ripple: $0) } }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipShape(.rect(cornerRadius: 28))
                .allowsHitTesting(false)
        }
        .overlay { RoundedRectangle(cornerRadius: 28).strokeBorder(Color.surfaceBorder) }
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .named("root")) } action: { cardFrame = $0 }
        .animation(.easeInOut(duration: 0.25), value: solved)
    }

    private var solveButton: some View {
        Button { fire(at: lastTouch) } label: {
            ButtonFace(solved: solved, count: todayCount)
        }
        .buttonStyle(PressScaleStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .named("root"))
                .onChanged { value in
                    if value.translation == .zero {
                        // Touch-down: warm up engines so release feedback is instant.
                        Haptics.shared.prepare()
                        Chime.shared.prepare()
                    }
                    lastTouch = value.location
                }
        )
        .background {
            if !solved && !reduceMotion {
                Circle()
                    .fill(Color.emerald.opacity(0.25))
                    .frame(width: 200, height: 200)
                    .blur(radius: 30)
                    .phaseAnimator([false, true]) { glow, on in
                        glow.scaleEffect(on ? 1.06 : 0.94).opacity(on ? 0.9 : 0.35)
                    } animation: { _ in .easeInOut(duration: 1.8) }
            }
        }
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .named("root")) } action: { buttonFrame = $0 }
        .accessibilityLabel(solved ? "\(todayCount) solved today. Log another" : "Mark today's problem as solved")
        .accessibilityIdentifier("solve-button")
    }

    private var noteField: some View {
        VStack(alignment: .leading, spacing: 6) {
            TextField("Problem / pattern (optional)", text: $note)
                .focused($noteFocused)
                .submitLabel(.done)
                .onSubmit { fire(at: nil) } // Return logs a solve
                .autocorrectionDisabled()
                .padding(.horizontal, 14)
                .frame(height: 48)
                .background(Color.black.opacity(0.4), in: .rect(cornerRadius: 12))
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(noteFocused ? Color.emerald.opacity(0.4) : Color.white.opacity(0.07))
                }
            if !solved {
                Text("e.g. 33. Search in Rotated Sorted Array | Binary Search")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 4)
            }
        }
    }

    private func fire(at touch: CGPoint?) {
        let location = touch ?? CGPoint(x: buttonFrame.midX, y: buttonFrame.midY)
        if !reduceMotion {
            let local = CGPoint(x: location.x - cardFrame.minX, y: location.y - cardFrame.minY)
            // Radius that reaches the farthest corner so the ring sweeps the whole card.
            let reach = hypot(max(local.x, cardFrame.width - local.x), max(local.y, cardFrame.height - local.y))
            let ripple = Ripple(center: local, radius: solved ? reach * 0.5 : reach)
            ripples.append(ripple)
            Task {
                try? await Task.sleep(for: .milliseconds(750))
                ripples.removeAll { $0.id == ripple.id }
            }
        }
        onSolve(note, location)
        note = ""
        noteFocused = false
    }
}
