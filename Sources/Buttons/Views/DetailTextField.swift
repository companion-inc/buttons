import SwiftUI

struct DetailTextField: View {
    let label: String
    @Binding var text: String
    var axis: Axis = .horizontal

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption.bold())
                .foregroundStyle(.secondary)

            TextField(label, text: $text, axis: axis)
                .textFieldStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(.black.opacity(0.045))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }
}
