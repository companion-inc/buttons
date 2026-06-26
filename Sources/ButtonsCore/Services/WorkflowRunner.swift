import AppKit
import Foundation

public typealias ButtonRunEventHandler = @MainActor (String) -> Void

@MainActor
public final class WorkflowRunner {
    private let shell: ShellCommandExecutor
    private let localAgents: LocalAgentRunner
    private let automationWorkspace: ButtonAutomationWorkspace

    public init(
        shell: ShellCommandExecutor = ShellCommandExecutor(),
        localAgents: LocalAgentRunner = LocalAgentRunner(),
        automationWorkspace: ButtonAutomationWorkspace = .production()
    ) {
        self.shell = shell
        self.localAgents = localAgents
        self.automationWorkspace = automationWorkspace
    }

    public func run(
        button: ActionButton,
        prompt: String,
        configurationOverride: AIConfiguration? = nil,
        eventHandler: ButtonRunEventHandler? = nil
    ) async -> ButtonRunReceipt {
        let startedAt = Date()
        eventHandler?("Started \(button.title).")

        do {
            var outputs: [String] = []
            for step in button.workflow.steps {
                eventHandler?("Starting \(step.title).")
                let result = try await run(
                    button: button,
                    step: step,
                    prompt: prompt,
                    configurationOverride: configurationOverride,
                    eventHandler: eventHandler
                )
                if !result.isEmpty {
                    outputs.append(result)
                }
            }

            let receipt = ButtonRunReceipt(
                buttonID: button.id,
                buttonTitle: button.title,
                startedAt: startedAt,
                finishedAt: Date(),
                status: .succeeded,
                summary: "\(button.title) finished.",
                output: outputs.joined(separator: "\n")
            )
            eventHandler?("Finished \(button.title).")
            try? automationWorkspace.writeRunLog(receipt, for: button)
            eventHandler?("Saved run log.")
            return receipt
        } catch is CancellationError {
            let receipt = ButtonRunReceipt(
                buttonID: button.id,
                buttonTitle: button.title,
                startedAt: startedAt,
                finishedAt: Date(),
                status: .canceled,
                summary: "\(button.title) stopped.",
                output: "Stopped by user."
            )
            eventHandler?("Stopped by user.")
            try? automationWorkspace.writeRunLog(receipt, for: button)
            return receipt
        } catch {
            let receipt = ButtonRunReceipt(
                buttonID: button.id,
                buttonTitle: button.title,
                startedAt: startedAt,
                finishedAt: Date(),
                status: .failed,
                summary: "\(button.title) failed.",
                output: (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            )
            eventHandler?("Failed: \(receipt.output)")
            try? automationWorkspace.writeRunLog(receipt, for: button)
            return receipt
        }
    }

    private func run(
        button: ActionButton,
        step: WorkflowStep,
        prompt: String,
        configurationOverride: AIConfiguration?,
        eventHandler: ButtonRunEventHandler?
    ) async throws -> String {
        switch step.kind {
        case .openURL:
            guard let url = URL(string: step.value) else {
                throw WorkflowRunError.invalidURL(step.value)
            }
            NSWorkspace.shared.open(url)
            return "Opened \(step.value)"

        case .copyText:
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(step.value, forType: .string)
            return "Copied text."

        case .runShortcut:
            let shortcutName = step.value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !shortcutName.isEmpty else {
                throw WorkflowRunError.missingShortcutName
            }
            let escaped = shortcutName.replacingOccurrences(of: "'", with: "'\\''")
            let output = try await shell.run("shortcuts run '\(escaped)'")
            return output.isEmpty ? "Ran Shortcut \(shortcutName)." : output

        case .runShellCommand:
            return try await shell.run(step.value)

        case .showMessage:
            return step.value

        case .askAI:
            return try await runAgentTask(
                button: button,
                step: step,
                prompt: prompt,
                configurationOverride: configurationOverride,
                eventHandler: eventHandler
            )
        }
    }

    private func runAgentTask(
        button: ActionButton,
        step: WorkflowStep,
        prompt: String,
        configurationOverride: AIConfiguration?,
        eventHandler: ButtonRunEventHandler?
    ) async throws -> String {
        guard let configuration = configurationOverride ?? step.aiConfiguration else {
            throw WorkflowRunError.missingAIConfiguration
        }

        eventHandler?("Preparing button workspace.")
        let workspaceURL = try automationWorkspace.ensureWorkspace(for: button)
        let agentConfiguration = buttonAgentConfiguration(
            configuration: configuration,
            workspaceURL: workspaceURL
        )
        let context = buttonContext(
            button: button,
            prompt: prompt,
            workspaceURL: workspaceURL
        )
        try automationWorkspace.writeContext(context, for: button)
        eventHandler?("Wrote button context.")

        eventHandler?("Running \(configuration.provider.shortTitle).")
        let agentOutput = try await localAgents.run(
            configuration: agentConfiguration,
            prompt: agentRunPrompt(context: context),
            environmentOverrides: buttonEnvironment(
                button: button,
                prompt: prompt,
                workspaceURL: workspaceURL
            )
        )
        let completion = Self.interpretedAgentCompletion(agentOutput)
        guard !completion.isFailed else {
            throw WorkflowRunError.agentTaskFailed(completion.output)
        }

        eventHandler?("\(configuration.provider.shortTitle) returned.")

        return """
        Agent ran this button.
        Workspace: \(workspaceURL.path)

        \(completion.output)
        """
    }

    private func buttonContext(
        button: ActionButton,
        prompt: String,
        workspaceURL: URL
    ) -> String {
        """
        Button: \(button.title)
        Button ID: \(button.id.uuidString)
        Button slug: \(button.slug)
        Category: \(button.category)
        Goal: \(button.taskDescription)

        Run prompt:
        \(prompt)

        Button workspace:
        \(workspaceURL.path)

        Button logs directory:
        \(automationWorkspace.logsURL(for: button).path)

        Values the agent should treat as the button environment:
        - BUTTON_ID
        - BUTTON_SLUG
        - BUTTON_TITLE
        - BUTTON_RUN_PROMPT
        - BUTTON_WORKSPACE
        - BUTTON_LOGS_DIRECTORY
        """
    }

    private func agentRunPrompt(context: String) -> String {
        """
        You are running a Buttons button.

        Complete the saved button instruction now.

        Requirements:
        - Execute the run prompt end to end before reporting back.
        - Treat the run prompt as the only user-provided input for this click.
        - Prefer structured app, API, and CLI routes over visible GUI control.
        - Do not use Computer Use unless the saved instruction explicitly asks for visible desktop or browser control.
        - Report concise status in your final output. Buttons saves the run log; do not create a separate run log unless the saved instruction asks for one.
        - Do not hardcode secrets.
        - Do not stop at planning or at writing files; finish the actual task.
        - Begin the final output with `BUTTONS_RUN_DONE:` when the saved instruction completed.
        - Begin the final output with `BUTTONS_RUN_FAILED:` when the saved instruction did not complete, then state the blocker.

        \(context)
        """
    }

    private func buttonEnvironment(
        button: ActionButton,
        prompt: String,
        workspaceURL: URL
    ) -> [String: String] {
        [
            "BUTTON_ID": button.id.uuidString,
            "BUTTON_SLUG": button.slug,
            "BUTTON_TITLE": button.title,
            "BUTTON_RUN_PROMPT": prompt,
            "BUTTON_WORKSPACE": workspaceURL.path,
            "BUTTON_LOGS_DIRECTORY": automationWorkspace.logsURL(for: button).path,
        ]
    }

    private func buttonAgentConfiguration(configuration: AIConfiguration, workspaceURL: URL) -> AIConfiguration {
        AIConfiguration(
            provider: configuration.provider,
            model: configuration.model,
            systemPrompt: configuration.systemPrompt,
            executionMode: configuration.executionMode,
            workingDirectory: workspaceURL.path,
            thinkingLevel: configuration.thinkingLevel
        )
    }

    nonisolated static func interpretedAgentCompletion(_ output: String) -> AgentCompletion {
        let doneMarker = "BUTTONS_RUN_DONE:"
        let failedMarker = "BUTTONS_RUN_FAILED:"
        let trimmedOutput = output.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let firstLine = trimmedOutput
            .components(separatedBy: .newlines)
            .first(where: { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })?
            .trimmingCharacters(in: .whitespacesAndNewlines) else {
            return AgentCompletion(output: "", isFailed: false)
        }

        if firstLine.hasPrefix(doneMarker) {
            return AgentCompletion(
                output: trimmedOutput.removingFirstLineMarker(doneMarker),
                isFailed: false
            )
        }

        if firstLine.hasPrefix(failedMarker) {
            return AgentCompletion(
                output: trimmedOutput.removingFirstLineMarker(failedMarker),
                isFailed: true
            )
        }

        return AgentCompletion(output: trimmedOutput, isFailed: false)
    }
}

struct AgentCompletion: Equatable, Sendable {
    var output: String
    var isFailed: Bool
}

private extension String {
    func removingFirstLineMarker(_ marker: String) -> String {
        var lines = components(separatedBy: .newlines)

        for index in lines.indices {
            let trimmedLine = lines[index].trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedLine.isEmpty else {
                continue
            }

            let replacement = String(trimmedLine.dropFirst(marker.count))
                .trimmingCharacters(in: .whitespacesAndNewlines)
            lines[index] = replacement
            break
        }

        return lines
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
