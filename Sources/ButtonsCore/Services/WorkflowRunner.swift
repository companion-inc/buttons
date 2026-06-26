import AppKit
import Foundation

public typealias ButtonRunEventHandler = @MainActor (String) -> Void

@MainActor
public final class WorkflowRunner {
    private let shell: ShellCommandExecutor
    private let localAgents: LocalAgentRunner
    private let automationWorkspace: ButtonAutomationWorkspace
    private let computerUseRuntime: ComputerUseRuntime

    public init(
        shell: ShellCommandExecutor = ShellCommandExecutor(),
        localAgents: LocalAgentRunner = LocalAgentRunner(),
        automationWorkspace: ButtonAutomationWorkspace = .production(),
        computerUseRuntime: ComputerUseRuntime = ComputerUseRuntime()
    ) {
        self.shell = shell
        self.localAgents = localAgents
        self.automationWorkspace = automationWorkspace
        self.computerUseRuntime = computerUseRuntime
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
        eventHandler?("Refreshing computer-use context.")
        let computerUseContext = await computerUseRuntime.collect(
            for: button,
            workspace: automationWorkspace
        )
        let computerUseRuntimeURL = computerUseRuntime.executableURL()
        eventHandler?("Computer-use context ready.")
        let agentConfiguration = buttonAgentConfiguration(
            configuration: configuration,
            workspaceURL: workspaceURL
        )
        let context = buttonContext(
            button: button,
            prompt: prompt,
            workspaceURL: workspaceURL,
            computerUseContext: computerUseContext,
            computerUseRuntimeURL: computerUseRuntimeURL
        )
        try automationWorkspace.writeContext(context, for: button)
        eventHandler?("Wrote button context.")

        eventHandler?("Running \(configuration.provider.shortTitle).")
        let agentOutput = try await localAgents.run(
            configuration: agentConfiguration,
            prompt: agentRunPrompt(
                context: context,
                existingAutomation: automationWorkspace.readAutomation(for: button)
            ),
            environmentOverrides: buttonEnvironment(
                button: button,
                prompt: prompt,
                workspaceURL: workspaceURL,
                computerUseContext: computerUseContext,
                computerUseRuntimeURL: computerUseRuntimeURL
            )
        )
        automationWorkspace.markAutomationExecutable(for: button)
        eventHandler?("\(configuration.provider.shortTitle) returned.")
        eventHandler?("Updated button memory.")

        return """
        Agent ran this button and updated its optimization memory.
        Workspace: \(workspaceURL.path)

        \(agentOutput)
        """
    }

    private func buttonContext(
        button: ActionButton,
        prompt: String,
        workspaceURL: URL,
        computerUseContext: ComputerUseContextSnapshot,
        computerUseRuntimeURL: URL?
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

        Computer use context:
        \(computerUseContext.contextURL.path)

        Computer use runtime:
        \(computerUseRuntimeURL?.path ?? "ButtonsComputerUseRuntime is not installed beside Buttons.")

        Computer use summary:
        \(computerUseContext.summary)

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
        - BUTTON_COMPUTER_USE_DIRECTORY
        - BUTTON_COMPUTER_USE_CONTEXT
        - BUTTON_COMPUTER_USE_RUNTIME
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
        - Read the computer-use context before doing any desktop, browser, app, visual, or UI task.
        - Use `computer-use/context.md`, `computer-use/accessibility-tree.md`, and `computer-use/screen-*.jpg` as the current visible computer state.
        - Treat `BUTTON_COMPUTER_USE_RUNTIME` as the product computer-use helper for this run.
        - Follow the computer-use loop in `computer-use/TOOLS.md`: snapshot, act with the narrowest available route, then verify from fresh state.
        - Prefer structured app/API/CLI routes when they complete the task without visible GUI control.
        - Do not use shell `open`, AppleScript, `osascript`, `cliclick`, raw CGEvent helpers, Cmd-Tab, or browser address-bar hotkeys as the normal computer-use route.
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

    private func buttonEnvironment(
        button: ActionButton,
        prompt: String,
        workspaceURL: URL,
        computerUseContext: ComputerUseContextSnapshot,
        computerUseRuntimeURL: URL?
    ) -> [String: String] {
        var environment = [
            "BUTTON_ID": button.id.uuidString,
            "BUTTON_SLUG": button.slug,
            "BUTTON_TITLE": button.title,
            "BUTTON_RUN_PROMPT": prompt,
            "BUTTON_WORKSPACE": workspaceURL.path,
            "BUTTON_AUTOMATION_PATH": automationWorkspace.runnerURL(for: button).path,
            "BUTTON_SKILLS_DIRECTORY": automationWorkspace.skillsURL(for: button).path,
            "BUTTON_LOGS_DIRECTORY": automationWorkspace.logsURL(for: button).path,
            "BUTTON_AGENT_DIRECTORY": automationWorkspace.agentURL(for: button).path,
            "BUTTON_COMPUTER_USE_DIRECTORY": automationWorkspace.computerUseURL(for: button).path,
            "BUTTON_COMPUTER_USE_CONTEXT": computerUseContext.contextURL.path,
        ]

        if let computerUseRuntimeURL {
            environment["BUTTON_COMPUTER_USE_RUNTIME"] = computerUseRuntimeURL.path
        }

        return environment
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
