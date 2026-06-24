import ButtonsCore
import SwiftUI

struct RunConfirmationView: View {
    let button: ActionButton
    let namespace: Namespace.ID
    @Binding var doNotAskAgain: Bool
    let cancelAction: () -> Void
    let runAction: ([String: String]) -> Void
    @State private var values: [String: String]

    init(
        button: ActionButton,
        namespace: Namespace.ID,
        doNotAskAgain: Binding<Bool>,
        cancelAction: @escaping () -> Void,
        runAction: @escaping ([String: String]) -> Void
    ) {
        self.button = button
        self.namespace = namespace
        _doNotAskAgain = doNotAskAgain
        self.cancelAction = cancelAction
        self.runAction = runAction
        _values = State(initialValue: Dictionary(uniqueKeysWithValues: button.workflow.inputs.map { ($0.key, $0.defaultValue) }))
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 42, style: .continuous)
                .fill(Color(red: 0.96, green: 0.96, blue: 0.94))
                .matchedGeometryEffect(
                    id: "button-\(button.id.uuidString)",
                    in: namespace,
                    properties: .frame,
                    isSource: false
                )
                .shadow(color: button.face.color.swiftUIColor.opacity(0.26), radius: 36, y: 22)

            RoundedRectangle(cornerRadius: 42, style: .continuous)
                .fill(screenBackground)

            VStack(alignment: .leading, spacing: 18) {
                header
                Text(button.taskDescription)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.black.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                inputFields

                Toggle("Do not ask again for this button", isOn: $doNotAskAgain)
                    .toggleStyle(.checkbox)
                    .font(.callout.weight(.medium))

                HStack(spacing: 12) {
                    Button("Cancel", systemImage: "xmark", action: cancelAction)
                        .buttonStyle(ChromePillButtonStyle(tint: .black.opacity(0.46)))

                    Spacer()

                    Button("Run", systemImage: "play.fill", action: run)
                        .buttonStyle(AgentLaunchButtonStyle(color: button.face.color.swiftUIColor))
                }
            }
            .padding(24)
            .frame(width: 560)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .strokeBorder(.white.opacity(0.70), lineWidth: 1)
            )
            .shadow(color: button.face.color.swiftUIColor.opacity(0.20), radius: 28, y: 18)
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var header: some View {
        HStack(spacing: 14) {
            Image(systemName: button.face.symbolName)
                .font(.title2)
                .foregroundStyle(button.face.color.swiftUIForegroundColor)
                .frame(width: 52, height: 52)
                .background(button.face.color.swiftUIColor.gradient)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 6) {
                Text(button.title)
                    .font(.title2.bold())
                    .lineLimit(2)

                HStack(spacing: 8) {
                    Text(button.category)
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.black.opacity(0.06))
                        .clipShape(Capsule())

                    AgentBadgeView(provider: provider)
                }
            }

            Spacer()
        }
    }

    private var provider: AIProvider {
        button.workflow.steps.first?.aiConfiguration?.provider ?? .codex
    }

    @ViewBuilder
    private var inputFields: some View {
        if !button.workflow.inputs.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(button.workflow.inputs) { input in
                    DetailTextField(label: input.label, text: valueBinding(for: input))
                }
            }
        }
    }

    private var screenBackground: some ShapeStyle {
        LinearGradient(
            colors: [
                Color.white,
                button.face.color.swiftUIColor.opacity(0.18),
                Color(red: 0.91, green: 0.93, blue: 0.97),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func valueBinding(for input: ButtonInputField) -> Binding<String> {
        Binding(
            get: { values[input.key, default: input.defaultValue] },
            set: { values[input.key] = $0 }
        )
    }

    private func run() {
        runAction(values)
    }
}
