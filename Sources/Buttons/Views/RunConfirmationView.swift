import ButtonsCore
import SwiftUI

struct RunConfirmationView: View {
    let button: ActionButton
    let namespace: Namespace.ID
    let isRunning: Bool
    let receipt: ButtonRunReceipt?
    let runEvents: [String]
    let cancelAction: () -> Void
    let runAction: (String) -> Void

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 42)
                .fill(Color(red: 0.96, green: 0.96, blue: 0.94))
                .matchedGeometryEffect(
                    id: "button-\(button.id.uuidString)",
                    in: namespace,
                    properties: .frame,
                    isSource: false
                )
                .shadow(color: button.face.color.swiftUIColor.opacity(0.26), radius: 36, y: 22)

            RoundedRectangle(cornerRadius: 42)
                .fill(screenBackground)

            VStack(alignment: .leading, spacing: 18) {
                header
                runContent
                controls
            }
            .padding(24)
            .frame(width: 620)
            .background(Color.white.opacity(0.92))
            .clipShape(RoundedRectangle(cornerRadius: 32))
            .overlay(
                RoundedRectangle(cornerRadius: 32)
                    .strokeBorder(.white.opacity(0.76), lineWidth: 1)
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
            workspaceCard(title: "Button workspace", detail: workspacePath)
        } else if isRunning {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 10) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Running")
                        .font(.headline)
                }

                currentStateCard
                workspaceCard(title: "Button workspace", detail: workspacePath)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.black.opacity(0.045))
            .clipShape(RoundedRectangle(cornerRadius: 20))
        } else {
            VStack(alignment: .leading, spacing: 12) {
                Label("Armed", systemImage: "exclamationmark.triangle.fill")
                    .font(.headline)
                    .foregroundStyle(.orange)

                Text(prompt)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.black.opacity(0.045))
                    .clipShape(RoundedRectangle(cornerRadius: 18))

                workspaceCard(title: "Button workspace", detail: workspacePath)
            }
        }
    }

    private var currentStateCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(runEvents.last ?? "Starting.")
                .font(.callout.bold())
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
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var controls: some View {
        HStack(spacing: 12) {
            Button(leftControlTitle, systemImage: leftControlSymbol, action: cancelAction)
                .buttonStyle(ChromePillButtonStyle(tint: isRunning ? .red.opacity(0.82) : .black.opacity(0.46)))

            Spacer()

            if receipt == nil, !isRunning {
                Button("Run", systemImage: "play.fill", action: run)
                    .buttonStyle(AgentLaunchButtonStyle(color: button.face.color.swiftUIColor))
                    .disabled(prompt.isEmpty)
                    .opacity(prompt.isEmpty ? 0.42 : 1)
            }
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            Image(systemName: button.face.symbolName)
                .font(.title2)
                .foregroundStyle(button.face.color.swiftUIForegroundColor)
                .frame(width: 54, height: 54)
                .background(button.face.color.swiftUIColor.gradient)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 6) {
                Text(button.title)
                    .font(.title2.bold())
                    .lineLimit(2)

                Text(receipt == nil ? "Press again to run this button." : "Run finished.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
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
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var prompt: String {
        button.workflow.steps.first?.value.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    private var workspacePath: String {
        ButtonAutomationWorkspace.production().workspaceURL(for: button).path
    }

    private var leftControlTitle: String {
        if isRunning {
            return "Stop"
        }

        return receipt == nil ? "Back" : "Done"
    }

    private var leftControlSymbol: String {
        if isRunning {
            return "stop.fill"
        }

        return receipt == nil ? "chevron.left" : "checkmark"
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
