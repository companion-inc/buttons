import AppKit
import Foundation

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
        configurationOverride: AIConfiguration? = nil
    ) async -> ButtonRunReceipt {
        let startedAt = Date()

        do {
            var outputs: [String] = []
            for step in button.workflow.steps {
                let result = try await run(
                    button: button,
                    step: step,
                    prompt: prompt,
                    configurationOverride: configurationOverride
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
            try? automationWorkspace.writeRunLog(receipt, for: button)
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
            try? automationWorkspace.writeRunLog(receipt, for: button)
            return receipt
        }
    }

    private func run(
        button: ActionButton,
        step: WorkflowStep,
        prompt: String,
        configurationOverride: AIConfiguration?
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
                configurationOverride: configurationOverride
            )
        }
    }

    private func runAgentTask(
        button: ActionButton,
        step: WorkflowStep,
        prompt: String,
        configurationOverride: AIConfiguration?
    ) async throws -> String {
        guard let configuration = configurationOverride ?? step.aiConfiguration else {
            throw WorkflowRunError.missingAIConfiguration
        }

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

        let agentOutput = try await localAgents.run(
            configuration: agentConfiguration,
            prompt: agentRunPrompt(
                context: context,
                existingAutomation: automationWorkspace.readAutomation(for: button)
            )
        )
        automationWorkspace.markAutomationExecutable(for: button)

        return """
        Agent ran this button and updated its optimization memory.
        Workspace: \(workspaceURL.path)

        \(agentOutput)
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

        Optimization runner path:
        \(automationWorkspace.runnerURL(for: button).path)

        Button skills directory:
        \(automationWorkspace.skillsURL(for: button).path)

        Button logs directory:
        \(automationWorkspace.logsURL(for: button).path)

        Agent scratch directory:
        \(automationWorkspace.agentURL(for: button).path)

        Values the agent should treat as the button environment:
        - BUTTON_ID
        - BUTTON_SLUG
        - BUTTON_TITLE
        - BUTTON_RUN_PROMPT
        - BUTTON_WORKSPACE
        - BUTTON_AUTOMATION_PATH
        - BUTTON_SKILLS_DIRECTORY
        - BUTTON_LOGS_DIRECTORY
        - BUTTON_AGENT_DIRECTORY
        """
    }

    private func agentRunPrompt(context: String, existingAutomation: String) -> String {
        """
        You are running a Buttons button.

        Complete the button's run now. Every click belongs to the local AI agent. The button workspace is durable memory that should make later clicks cheaper, faster, or more reliable.

        Requirements:
        - Execute the run prompt end to end before reporting back.
        - Treat the run prompt as the only user-provided input for this click.
        - Read and update the button workspace when it helps future runs.
        - Use the optimization runner path only as an internal acceleration artifact.
        - Use the skills directory for durable notes, procedures, and button-specific reusable instructions.
        - Use the agent scratch directory for temporary repair or improvement work.
        - Reuse existing automation when it is correct, repair it when it is broken, and replace it when the task has changed.
        - Keep anything reusable idempotent and non-interactive.
        - Print useful logs.
        - Do not hardcode secrets.
        - Do not stop at planning or at writing files; finish the actual task.
        - End with what happened and what the button learned for next time.
        - In the final user-facing result, call durable artifacts automation, runners, notes, or memory. Do not describe them as scripts.

        \(context)

        Existing optimization:
        ```text
        \(existingAutomation.isEmpty ? "None yet." : existingAutomation)
        ```
        """
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
}
