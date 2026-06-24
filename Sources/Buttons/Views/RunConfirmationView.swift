import ButtonsCore
import SwiftUI

struct RunConfirmationView: View {
    let button: ActionButton
    let namespace: Namespace.ID
    let isRunning: Bool
    let receipt: ButtonRunReceipt?
    let cancelAction: () -> Void
    let runAction: (String) -> Void
    @State private var prompt: String

    init(
        button: ActionButton,
        namespace: Namespace.ID,
        isRunning: Bool,
        receipt: ButtonRunReceipt?,
        cancelAction: @escaping () -> Void,
        runAction: @escaping (String) -> Void
    ) {
        self.button = button
        self.namespace = namespace
        self.isRunning = isRunning
        self.receipt = receipt
        self.cancelAction = cancelAction
        self.runAction = runAction
        _prompt = State(initialValue: button.workflow.steps.first?.value ?? button.taskDescription)
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

                runContent
                controls
            }
            .padding(24)
            .frame(width: 600)
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

    @ViewBuilder
    private var runContent: some View {
        if let receipt {
            RunHistoryRow(receipt: receipt)
            workspaceCard(title: "Saved in", detail: workspacePath)
        } else if isRunning {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 10) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Running \(provider.shortTitle)")
                        .font(.headline)
                }

                workspaceCard(title: "Workspace", detail: workspacePath)
                workspaceCard(title: "Script", detail: scriptPath)

                Text("Buttons is building, running, or repairing this button's reusable script.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.black.opacity(0.045))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        } else {
            VStack(alignment: .leading, spacing: 12) {
                DetailTextField(label: "Run prompt", text: $prompt, axis: .vertical, minHeight: 168)

                workspaceCard(title: "Workspace", detail: workspacePath)
            }
        }
    }

    private var controls: some View {
        HStack(spacing: 12) {
            Button(receipt == nil ? "Cancel" : "Done", systemImage: receipt == nil ? "xmark" : "checkmark", action: cancelAction)
                .buttonStyle(ChromePillButtonStyle(tint: .black.opacity(0.46)))
                .disabled(isRunning)

            Spacer()

            if receipt == nil {
                Button(isRunning ? "Running..." : "Run", systemImage: "play.fill", action: run)
                    .buttonStyle(AgentLaunchButtonStyle(color: button.face.color.swiftUIColor))
                    .disabled(isRunning)
            }
        }
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

    private func workspaceCard(title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.bold())
                .foregroundStyle(.secondary)

            Text(detail)
                .font(.caption.monospaced())
                .lineLimit(2)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(.black.opacity(0.045))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var provider: AIProvider {
        button.workflow.steps.first?.aiConfiguration?.provider ?? .codex
    }

    private var workspacePath: String {
        ButtonAutomationWorkspace.production().workspaceURL(for: button).path
    }

    private var scriptPath: String {
        ButtonAutomationWorkspace.production().scriptURL(for: button).path
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

    private func run() {
        runAction(prompt)
    }
}
