import Combine
import OSLog
import SwiftUI

@main
struct DSAMatrixApp: App {
    @State private var model: AppModel
    @Environment(\.scenePhase) private var scenePhase

    init() {
        let arguments = ProcessInfo.processInfo.arguments
        let store: SolveStore?
        do {
            store = try SolveStore(inMemory: arguments.contains("-inMemory"))
        } catch {
            Logger.store.critical("Store failed to open: \(String(describing: error), privacy: .public)")
            store = nil
        }
        let model = AppModel(store: store)
        #if DEBUG
        if arguments.contains("-seed") { model.seedDemoHistory() }
        #endif
        _model = State(initialValue: model)
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(model)
                .preferredColorScheme(.dark)
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active { model.reload() } // picks up widget "+" taps and a new day
                }
                .onReceive(dayChanges) { _ in model.reload() }
        }
    }

    private var dayChanges: AnyPublisher<Notification, Never> {
        let center = NotificationCenter.default
        return center.publisher(for: .NSCalendarDayChanged)
            .merge(with: center.publisher(for: UIApplication.significantTimeChangeNotification))
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}
