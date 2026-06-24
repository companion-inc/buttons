import ButtonsCore
import SwiftUI

struct RunHistoryRow: View {
    let receipt: ButtonRunReceipt

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(receipt.status == .succeeded ? "Succeeded" : "Failed", systemImage: receipt.status == .succeeded ? "checkmark.circle.fill" : "xmark.octagon.fill")
                    .foregroundStyle(receipt.status == .succeeded ? .green : .red)
                    .font(.headline)

                Spacer()

                Text(receipt.startedAt, style: .date)
                    .foregroundStyle(.secondary)
                Text(receipt.startedAt, style: .time)
                    .foregroundStyle(.secondary)
            }

            Text(receipt.summary)
                .font(.callout)
                .foregroundStyle(.secondary)

            if !receipt.output.isEmpty {
                Text(receipt.output)
                    .font(.caption.monospaced())
                    .lineLimit(8)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(.black.opacity(0.055))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        }
        .padding(16)
        .background(.white.opacity(0.66))
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .strokeBorder(.white.opacity(0.7), lineWidth: 1)
        )
    }
}
