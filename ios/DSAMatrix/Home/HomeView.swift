import SwiftUI

struct HomeView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var particles = ParticleSystem()
    @State private var toast: UndoToast.Item?
    @State private var selectedDay: Day?
    @State private var popDay: Day?
    @State private var popCount = 0

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                TopBar(stats: model.stats)
                if let message = model.errorMessage {
                    Label(message, systemImage: "exclamationmark.triangle.fill")
                        .font(.footnote)
                        .foregroundStyle(Color.amber)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                HeroCard(onSolve: handleSolve)
                // Task 9: HeatmapCard goes here.
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 80)
        }
        .scrollDismissesKeyboard(.interactively)
        .coordinateSpace(.named("root"))
        .overlay { ParticleLayer(system: particles) }
        .overlay(alignment: .bottom) {
            if let toast {
                UndoToast(item: toast) {
                    model.delete(toast.record.id)
                    Haptics.shared.play(.tick)
                    self.toast = nil
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.35), value: toast)
        .task(id: toast?.id) {
            guard toast != nil else { return }
            try? await Task.sleep(for: .seconds(4))
            if !Task.isCancelled { toast = nil }
        }
        .background(Color.oled.ignoresSafeArea())
    }

    /// Haptic, sound, particles and the save all happen in the same run-loop turn.
    private func handleSolve(note: String, at location: CGPoint) {
        let isFirst = model.stats.todayCount == 0
        Haptics.shared.play(isFirst ? .success : .extra)
        Chime.shared.play(full: isFirst)
        if !reduceMotion { particles.burst(at: location, big: isFirst) }
        guard let record = model.logSolve(note: note) else { return }
        if isFirst {
            popDay = record.day
            popCount += 1
        }
        toast = UndoToast.Item(record: record)
    }
}
