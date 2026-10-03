import SwiftUI

struct UndoToast: View {
    struct Item: Identifiable, Equatable {
        let id = UUID()
        let record: SolveRecord
    }

    let item: Item
    let onUndo: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.emeraldLight)
            Text("Logged “\(item.record.title)”")
                .font(.subheadline)
                .lineLimit(1)
            Spacer(minLength: 8)
            Button("Undo", action: onUndo)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.emeraldLight)
        }
        .padding(.horizontal, 18)
        .frame(height: 50)
        .glassEffect()
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}
