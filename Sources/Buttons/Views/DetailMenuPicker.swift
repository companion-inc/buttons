import SwiftUI

struct DetailMenuPicker<SelectionValue: Hashable, Content: View>: View {
    let label: String
    @Binding var selection: SelectionValue
    @ViewBuilder let content: Content

    var body: some View {
        HStack {
            Text(label)
                .font(.caption.bold())
                .foregroundStyle(.secondary)

            Spacer()

            Picker(label, selection: $selection) {
                content
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .frame(maxWidth: 210, alignment: .trailing)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.black.opacity(0.045))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
