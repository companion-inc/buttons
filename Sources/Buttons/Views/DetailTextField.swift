import SwiftUI

struct DetailTextField: View {
    let label: String
    @Binding var text: String
    var axis: Axis = .horizontal
    var minHeight: CGFloat?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption.bold())
                .foregroundStyle(.secondary)

            field
                .padding(.horizontal, 12)
                .padding(.vertical, axis == .vertical ? 8 : 10)
                .background(.black.opacity(0.045))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    @ViewBuilder
    private var field: some View {
        if axis == .vertical {
            DetailMultilineTextView(text: $text)
                .frame(height: minHeight ?? 110)
                .frame(maxWidth: .infinity, alignment: .topLeading)
        } else {
            TextField(label, text: $text, axis: axis)
                .textFieldStyle(.plain)
        }
    }
}
