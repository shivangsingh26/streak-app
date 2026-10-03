import SwiftUI

enum EditorTarget: Identifiable {
    case add
    case edit(SolveRecord)

    var id: String {
        switch self {
        case .add: "add"
        case .edit(let record): record.id.uuidString
        }
    }
}

struct DaySheet: View {
    let day: Day

    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var editor: EditorTarget?

    var body: some View {
        let records = model.records(on: day)
        NavigationStack {
            List {
                if records.isEmpty {
                    ContentUnavailableView("Nothing logged", systemImage: "square.dashed",
                                           description: Text("Tap + to add a problem you solved this day."))
                }
                ForEach(records) { record in
                    Button { editor = .edit(record) } label: { SolveRow(record: record) }
                        .buttonStyle(.plain)
                }
                .onDelete { offsets in
                    for index in offsets { model.delete(records[index].id) }
                    Haptics.shared.play(.tick)
                }
            }
            .navigationTitle(day.startDate().formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()))
            .navigationSubtitle("\(records.count) solved")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Add solve", systemImage: "plus") { editor = .add }
                }
            }
            .sheet(item: $editor) { SolveEditor(day: day, target: $0) }
        }
        .presentationDetents([.medium, .large])
    }
}
