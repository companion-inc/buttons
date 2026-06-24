import ButtonsCore
import SwiftUI

struct RunButtonView: View {
    @Environment(\.dismiss) private var dismiss
    let button: ActionButton
    let runAction: ([String: String]) -> Void
    @State private var values: [String: String]

    init(button: ActionButton, runAction: @escaping ([String: String]) -> Void) {
        self.button = button
        self.runAction = runAction
        _values = State(initialValue: Dictionary(uniqueKeysWithValues: button.workflow.inputs.map { ($0.key, $0.defaultValue) }))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 14) {
                Image(systemName: button.face.symbolName)
                    .font(.title)
                    .frame(width: 48, height: 48)
                    .foregroundStyle(button.face.color.swiftUIForegroundColor)
                    .background(button.face.color.swiftUIColor)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text(button.title)
                        .font(.title2)
                        .bold()
                    Text(button.taskDescription)
                        .foregroundStyle(.secondary)
                }
            }

            if !button.workflow.inputs.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(button.workflow.inputs) { input in
                        TextField(input.label, text: valueBinding(for: input), prompt: Text(input.placeholder))
                    }
                }
            }

            if !button.permissions.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(button.permissions) { permission in
                        LabeledContent(permission.title) {
                            Text(permission.detail)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(14)
                .background(.quaternary)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            HStack {
                Spacer()
                Button("Cancel", action: dismiss.callAsFunction)
                Button("Run", action: run)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 520)
    }

    private func valueBinding(for input: ButtonInputField) -> Binding<String> {
        Binding(
            get: { values[input.key, default: input.defaultValue] },
            set: { values[input.key] = $0 }
        )
    }

    private func run() {
        runAction(values)
        dismiss()
    }
}
