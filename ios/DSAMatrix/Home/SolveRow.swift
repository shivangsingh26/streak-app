import SwiftUI

struct SolveRow: View {
    let record: SolveRecord

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(Color.emeraldLight)
                .frame(width: 6, height: 6)
                .padding(.top, 7)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(record.title)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                if let pattern = record.pattern {
                    Text(pattern)
                        .font(.caption2.monospaced())
                        .foregroundStyle(Color.emeraldLight)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.zincCell, in: .rect(cornerRadius: 6))
                }
            }
            Spacer(minLength: 8)
            Text(record.solvedAt, format: .dateTime.hour().minute())
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }
}
