import SwiftUI

struct SolveEditor: View {
    let day: Day
    let target: EditorTarget

    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var note: String
    @State private var time: Date

    init(day: Day, target: EditorTarget, now: Date = .now) {
        self.day = day
        self.target = target
        switch target {
        case .add:
            _note = State(initialValue: "")
            _time = State(initialValue: day == Day(now) ? now : day.date(hour: 12))
        case .edit(let record):
            _note = State(initialValue: record.note ?? "")
            _time = State(initialValue: record.solvedAt)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Problem / pattern (optional)", text: $note, axis: .vertical)
                    .lineLimit(1...3)
                    .autocorrectionDisabled()
                    .accessibilityIdentifier("editor-note")
                // Range keeps the time inside this day; moving a solve = delete + re-add.
                DatePicker("Time", selection: $time, in: day.timeRange(), displayedComponents: .hourAndMinute)
                if case .edit(let record) = target {
                    Section {
                        Button("Delete", role: .destructive) {
                            model.delete(record.id)
                            Haptics.shared.play(.tick)
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle(isAdding ? "Add solve" : "Edit solve")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save", action: save) }
            }
        }
        .presentationDetents([.medium])
        .presentationBackground(Color.surface)
    }

    private var isAdding: Bool {
        if case .add = target { true } else { false }
    }

    private func save() {
        switch target {
        case .add:
            model.logSolve(note: note, on: day, at: time)
            Haptics.shared.play(.extra)
        case .edit(let record):
            model.update(record.id, note: note, solvedAt: time)
        }
        dismiss()
    }
}
