import ButtonsCore
import SwiftUI

struct RunHistoryRow: View {
    let receipt: ButtonRunReceipt
    @State private var isLogExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(statusTitle, systemImage: statusSymbol)
                    .foregroundStyle(statusColor)
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
                DisclosureGroup(isExpanded: $isLogExpanded) {
                    Text(receipt.output)
                        .font(.caption.monospaced())
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(.black.opacity(0.055))
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .padding(.top, 4)
                } label: {
                    Text("Log")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                }
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

    private var statusTitle: String {
        switch receipt.status {
        case .succeeded:
            "Succeeded"
        case .failed:
            "Failed"
        case .canceled:
            "Stopped"
        }
    }

    private var statusSymbol: String {
        switch receipt.status {
        case .succeeded:
            "checkmark.circle.fill"
        case .failed:
            "xmark.octagon.fill"
        case .canceled:
            "stop.circle.fill"
        }
    }

    private var statusColor: Color {
        switch receipt.status {
        case .succeeded:
            .green
        case .failed:
            .red
        case .canceled:
            .secondary
        }
    }
}
