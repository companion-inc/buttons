import AppKit
import Foundation

@MainActor
public final class WorkflowRunner {
    private let shell: ShellCommandExecutor

    public init(shell: ShellCommandExecutor = ShellCommandExecutor()) {
        self.shell = shell
    }

    public func run(button: ActionButton, values: [String: String]) async -> ButtonRunReceipt {
        let startedAt = Date()

        do {
            var outputs: [String] = []
            for step in button.workflow.steps {
                let result = try await run(step: step, values: values)
                if !result.isEmpty {
                    outputs.append(result)
                }
            }

            return ButtonRunReceipt(
                buttonID: button.id,
                buttonTitle: button.title,
                startedAt: startedAt,
                finishedAt: Date(),
                status: .succeeded,
                summary: "\(button.title) finished.",
                output: outputs.joined(separator: "\n")
            )
        } catch {
            return ButtonRunReceipt(
                buttonID: button.id,
                buttonTitle: button.title,
                startedAt: startedAt,
                finishedAt: Date(),
                status: .failed,
                summary: "\(button.title) failed.",
                output: (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            )
        }
    }

    private func run(step: WorkflowStep, values: [String: String]) async throws -> String {
        let renderedValue = TemplateRenderer.render(step.value, values: values)

        switch step.kind {
        case .openURL:
            guard let url = URL(string: renderedValue) else {
                throw WorkflowRunError.invalidURL(renderedValue)
            }
            NSWorkspace.shared.open(url)
            return "Opened \(renderedValue)"

        case .copyText:
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(renderedValue, forType: .string)
            return "Copied text."

        case .runShortcut:
            let shortcutName = renderedValue.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !shortcutName.isEmpty else {
                throw WorkflowRunError.missingShortcutName
            }
            let escaped = shortcutName.replacingOccurrences(of: "'", with: "'\\''")
            let output = try await shell.run("shortcuts run '\(escaped)'")
            return output.isEmpty ? "Ran Shortcut \(shortcutName)." : output

        case .runShellCommand:
            return try await shell.run(renderedValue)

        case .showMessage:
            return renderedValue
        }
    }
}
