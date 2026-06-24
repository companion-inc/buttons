import AppKit
import Foundation

@MainActor
public final class WorkflowRunner {
    private let shell: ShellCommandExecutor
    private let localAgents: LocalAgentRunner
    private let commandLine: CommandLineExecutor
    private let automationWorkspace: ButtonAutomationWorkspace

    public init(
        shell: ShellCommandExecutor = ShellCommandExecutor(),
        localAgents: LocalAgentRunner = LocalAgentRunner(),
        commandLine: CommandLineExecutor = CommandLineExecutor(),
        automationWorkspace: ButtonAutomationWorkspace = .production()
    ) {
        self.shell = shell
        self.localAgents = localAgents
        self.commandLine = commandLine
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
        let scriptURL = automationWorkspace.scriptURL(for: button)
        let agentConfiguration = buttonAgentConfiguration(
            configuration: configuration,
            workspaceURL: workspaceURL
        )
        let context = buttonContext(
            button: button,
            prompt: prompt,
            scriptURL: scriptURL,
            workspaceURL: workspaceURL
        )
        try automationWorkspace.writeContext(context, for: button)

        if automationWorkspace.scriptExists(for: button) {
            let firstRun = try await runCachedScript(button: button, prompt: prompt, workspaceURL: workspaceURL)

            if firstRun.succeeded {
                return """
                Ran cached workflow script.
                Workspace: \(workspaceURL.path)
                Script: \(scriptURL.path)

                \(firstRun.combinedOutput)
                """
            }

            let repairOutput = try await localAgents.run(
                configuration: agentConfiguration,
                prompt: repairPrompt(
                    context: context,
                    script: automationWorkspace.readScript(for: button),
                    failure: firstRun.combinedOutput
                )
            )
            automationWorkspace.markScriptExecutable(for: button)

            let repairedRun = try await runCachedScript(button: button, prompt: prompt, workspaceURL: workspaceURL)

            guard repairedRun.succeeded else {
                throw WorkflowRunError.commandFailed(
                    """
                    Cached script failed, agent attempted repair, and the repaired script still failed.
                    Workspace: \(workspaceURL.path)
                    Script: \(scriptURL.path)

                    Initial failure:
                    \(firstRun.combinedOutput)

                    Agent repair log:
                    \(repairOutput)

                    Repaired script failure:
                    \(repairedRun.combinedOutput)
                    """
                )
            }

            return """
            Self-healed workflow script and ran it.
            Workspace: \(workspaceURL.path)
            Script: \(scriptURL.path)

            Script output:
            \(repairedRun.combinedOutput)

            Repair log:
            \(repairOutput)
            """
        }

        let buildOutput = try await localAgents.run(
            configuration: agentConfiguration,
            prompt: buildScriptPrompt(context: context)
        )
        automationWorkspace.markScriptExecutable(for: button)

        guard automationWorkspace.scriptExists(for: button) else {
            throw WorkflowRunError.commandFailed(
                """
                Agent did not create the reusable workflow script.
                Expected script: \(scriptURL.path)

                Agent output:
                \(buildOutput)
                """
            )
        }

        let generatedRun = try await runCachedScript(button: button, prompt: prompt, workspaceURL: workspaceURL)

        if generatedRun.succeeded {
            return """
            Extracted workflow into a reusable script and ran it.
            Workspace: \(workspaceURL.path)
            Script: \(scriptURL.path)

            Script output:
            \(generatedRun.combinedOutput)

            Agent build log:
            \(buildOutput)
            """
        }

        let repairOutput = try await localAgents.run(
            configuration: agentConfiguration,
            prompt: repairPrompt(
                context: context,
                script: automationWorkspace.readScript(for: button),
                failure: generatedRun.combinedOutput
            )
        )
        automationWorkspace.markScriptExecutable(for: button)

        let repairedRun = try await runCachedScript(button: button, prompt: prompt, workspaceURL: workspaceURL)

        guard repairedRun.succeeded else {
            throw WorkflowRunError.commandFailed(
                """
                Agent created a script, attempted one repair, and the script still failed.
                Workspace: \(workspaceURL.path)
                Script: \(scriptURL.path)

                Build log:
                \(buildOutput)

                First script failure:
                \(generatedRun.combinedOutput)

                Repair log:
                \(repairOutput)

                Repaired script failure:
                \(repairedRun.combinedOutput)
                """
            )
        }

        return """
        Extracted and self-healed workflow script.
        Workspace: \(workspaceURL.path)
        Script: \(scriptURL.path)

        Script output:
        \(repairedRun.combinedOutput)

        Build log:
        \(buildOutput)

        Repair log:
        \(repairOutput)
        """
    }

    private func runCachedScript(
        button: ActionButton,
        prompt: String,
        workspaceURL: URL
    ) async throws -> CommandLineResult {
        automationWorkspace.markScriptExecutable(for: button)
        return try await commandLine.run(
            executableURL: URL(filePath: "/bin/zsh"),
            arguments: [automationWorkspace.scriptURL(for: button).path],
            currentDirectoryURL: workspaceURL,
            environment: scriptEnvironment(button: button, prompt: prompt)
        )
    }

    private func scriptEnvironment(button: ActionButton, prompt: String) -> [String: String] {
        var environment = ProcessInfo.processInfo.environment
        environment["BUTTON_ID"] = button.id.uuidString
        environment["BUTTON_SLUG"] = button.slug
        environment["BUTTON_TITLE"] = button.title
        environment["BUTTON_RUN_PROMPT"] = prompt
        environment["BUTTON_WORKSPACE"] = automationWorkspace.workspaceURL(for: button).path
        environment["BUTTON_SCRIPT_PATH"] = automationWorkspace.scriptURL(for: button).path
        environment["BUTTON_SKILLS_DIRECTORY"] = automationWorkspace.skillsURL(for: button).path
        environment["BUTTON_LOGS_DIRECTORY"] = automationWorkspace.logsURL(for: button).path
        environment["BUTTON_AGENT_DIRECTORY"] = automationWorkspace.agentURL(for: button).path
        return environment
    }

    private func buttonContext(
        button: ActionButton,
        prompt: String,
        scriptURL: URL,
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

        Reusable script path:
        \(scriptURL.path)

        Button workspace:
        \(workspaceURL.path)

        Button skills directory:
        \(automationWorkspace.skillsURL(for: button).path)

        Button logs directory:
        \(automationWorkspace.logsURL(for: button).path)

        Agent scratch directory:
        \(automationWorkspace.agentURL(for: button).path)

        Environment variables available to the script:
        - BUTTON_ID
        - BUTTON_SLUG
        - BUTTON_TITLE
        - BUTTON_RUN_PROMPT
        - BUTTON_WORKSPACE
        - BUTTON_SCRIPT_PATH
        - BUTTON_SKILLS_DIRECTORY
        - BUTTON_LOGS_DIRECTORY
        - BUTTON_AGENT_DIRECTORY
        """
    }

    private func buildScriptPrompt(context: String) -> String {
        """
        You are running a Buttons self-healing workflow.

        The button must become cheaper each time it is clicked. Extract this repetitive workflow into a reusable zsh script at the exact path below, then make it executable.

        Requirements:
        - Create or overwrite the script at the reusable script path.
        - The script must be zsh.
        - Treat the button workspace as the durable home for this button.
        - Treat BUTTON_RUN_PROMPT as the only user-provided run input.
        - Use BUTTON_SKILLS_DIRECTORY for durable helper notes or button-specific reusable instructions.
        - Use BUTTON_AGENT_DIRECTORY for scratch files that help the local agent repair or improve the workflow.
        - Keep the script idempotent.
        - Do not require interactive input.
        - Print useful logs to stdout.
        - Do not hardcode secrets.
        - After writing the script, do not stop at an explanation.

        \(context)
        """
    }

    private func repairPrompt(context: String, script: String, failure: String) -> String {
        """
        This Buttons workflow has a cached reusable script, but it failed. Repair the script in place, preserve the original button goal, and make it executable again.

        \(context)

        Current script:
        ```zsh
        \(script)
        ```

        Failure output:
        ```
        \(failure)
        ```

        Fix the reusable script at the exact script path. Do not create a second script.
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
