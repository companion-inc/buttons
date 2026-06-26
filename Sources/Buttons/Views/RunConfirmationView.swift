import ButtonsCore
import SwiftUI

struct RunConfirmationView: View {
    let button: ActionButton
    let namespace: Namespace.ID
    let isRunning: Bool
    let receipt: ButtonRunReceipt?
    let runEvents: [String]
    let cancelAction: () -> Void
    let saveAction: (String) -> Void
    let runAction: (String) -> Void
    @State private var prompt: String
    @State private var didSavePrompt = false

    init(
        button: ActionButton,
        namespace: Namespace.ID,
        isRunning: Bool,
        receipt: ButtonRunReceipt?,
        runEvents: [String],
        cancelAction: @escaping () -> Void,
        saveAction: @escaping (String) -> Void,
        runAction: @escaping (String) -> Void
    ) {
        self.button = button
        self.namespace = namespace
        self.isRunning = isRunning
        self.receipt = receipt
        self.runEvents = runEvents
        self.cancelAction = cancelAction
        self.saveAction = saveAction
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
            if !runEvents.isEmpty {
                currentStateCard
            }
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

                currentStateCard
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.black.opacity(0.045))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        } else {
            VStack(alignment: .leading, spacing: 12) {
                DetailTextField(label: "Run prompt", text: $prompt, axis: .vertical, minHeight: 168)
                    .onChange(of: prompt) { _, _ in
                        didSavePrompt = false
                    }

                workspaceCard(title: "Workspace", detail: workspacePath)
            }
        }
    }

    private var currentStateCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Current state")
                .font(.caption.bold())
                .foregroundStyle(.secondary)

            Text(runEvents.last ?? "Starting.")
                .font(.callout.weight(.semibold))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            if runEvents.count > 1 {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(runEvents.suffix(5).enumerated()), id: \.offset) { _, event in
                        HStack(alignment: .top, spacing: 8) {
                            Circle()
                                .fill(button.face.color.swiftUIColor.opacity(0.72))
                                .frame(width: 6, height: 6)
                                .padding(.top, 6)
                            Text(event)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.black.opacity(0.045))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var controls: some View {
        HStack(spacing: 12) {
            Button(leftControlTitle, systemImage: leftControlSymbol, action: cancelAction)
                .buttonStyle(ChromePillButtonStyle(tint: isRunning ? .red.opacity(0.82) : .black.opacity(0.46)))

            Spacer()

            if receipt == nil, !isRunning {
                Button(saveControlTitle, systemImage: saveControlSymbol, action: save)
                    .buttonStyle(ChromePillButtonStyle(tint: didSavePrompt ? .green.opacity(0.72) : .black.opacity(0.52)))
                    .keyboardShortcut("s", modifiers: .command)

                Button("Run", systemImage: "play.fill", action: run)
                    .buttonStyle(AgentLaunchButtonStyle(color: button.face.color.swiftUIColor))
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

    private var leftControlTitle: String {
        if isRunning {
            return "Stop"
        }

        return receipt == nil ? "Cancel" : "Done"
    }

    private var leftControlSymbol: String {
        if isRunning {
            return "stop.fill"
        }

        return receipt == nil ? "xmark" : "checkmark"
    }

    private var saveControlTitle: String {
        didSavePrompt ? "Saved" : "Save"
    }

    private var saveControlSymbol: String {
        didSavePrompt ? "checkmark" : "tray.and.arrow.down"
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

    private func save() {
        saveAction(prompt)
        didSavePrompt = true
    }
}
