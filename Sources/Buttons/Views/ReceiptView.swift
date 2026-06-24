import ButtonsCore
import SwiftUI

struct ReceiptView: View {
    @Environment(\.dismiss) private var dismiss
    let receipt: ButtonRunReceipt

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Image(systemName: receipt.status == .succeeded ? "checkmark.circle.fill" : "xmark.octagon.fill")
                    .font(.largeTitle)
                    .foregroundStyle(receipt.status == .succeeded ? .green : .red)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text(receipt.buttonTitle)
                        .font(.title2)
                        .bold()
                    Text(receipt.summary)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            if !receipt.output.isEmpty {
                ScrollView {
                    Text(receipt.output)
                        .font(.system(.body, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                        .padding(14)
                }
                .frame(minHeight: 140)
                .background(.quaternary)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            HStack {
                Spacer()
                Button("Done", action: dismiss.callAsFunction)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 520)
    }
}
