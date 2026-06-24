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
        values: [String: String],
        configurationOverride: AIConfiguration? = nil
    ) async -> ButtonRunReceipt {
        let startedAt = Date()

        do {
            var outputs: [String] = []
            for step in button.workflow.steps {
                let result = try await run(
                    button: button,
                    step: step,
                    values: values,
                    configurationOverride: configurationOverride
                )
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

    private func run(
        button: ActionButton,
        step: WorkflowStep,
        values: [String: String],
        configurationOverride: AIConfiguration?
    ) async throws -> String {
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

        case .askAI:
            return try await runAgentTask(
                button: button,
                step: step,
                values: values,
                prompt: renderedValue,
                configurationOverride: configurationOverride
            )
        }
    }

    private func runAgentTask(
        button: ActionButton,
        step: WorkflowStep,
        values: [String: String],
        prompt: String,
        configurationOverride: AIConfiguration?
    ) async throws -> String {
        guard let configuration = configurationOverride ?? step.aiConfiguration else {
            throw WorkflowRunError.missingAIConfiguration
        }

        let workspaceURL = try automationWorkspace.ensureWorkspace(for: button.id)
        let scriptURL = automationWorkspace.scriptURL(for: button.id)
        let context = buttonContext(
            button: button,
            prompt: prompt,
            values: values,
            configuration: configuration,
            scriptURL: scriptURL
        )
        try automationWorkspace.writeContext(context, for: button.id)

        if automationWorkspace.scriptExists(for: button.id) {
            let firstRun = try await runCachedScript(
                buttonID: button.id,
                values: values,
                configuration: configuration
            )

            if firstRun.succeeded {
                return """
                Ran cached workflow script.
                Script: \(scriptURL.path)

                \(firstRun.combinedOutput)
                """
            }

            let repairOutput = try await localAgents.run(
                configuration: configuration,
                prompt: repairPrompt(
                    context: context,
                    script: automationWorkspace.readScript(for: button.id),
                    failure: firstRun.combinedOutput
                ),
                additionalWritableDirectories: [workspaceURL.path]
            )
            automationWorkspace.markScriptExecutable(for: button.id)

            let repairedRun = try await runCachedScript(
                buttonID: button.id,
                values: values,
                configuration: configuration
            )

            guard repairedRun.succeeded else {
                throw WorkflowRunError.commandFailed(
                    """
                    Cached script failed, agent attempted repair, and the repaired script still failed.
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
            Script: \(scriptURL.path)

            Script output:
            \(repairedRun.combinedOutput)

            Repair log:
            \(repairOutput)
            """
        }

        let buildOutput = try await localAgents.run(
            configuration: configuration,
            prompt: buildScriptPrompt(context: context),
            additionalWritableDirectories: [workspaceURL.path]
        )
        automationWorkspace.markScriptExecutable(for: button.id)

        guard automationWorkspace.scriptExists(for: button.id) else {
            throw WorkflowRunError.commandFailed(
                """
                Agent did not create the reusable workflow script.
                Expected script: \(scriptURL.path)

                Agent output:
                \(buildOutput)
                """
            )
        }

        let generatedRun = try await runCachedScript(
            buttonID: button.id,
            values: values,
            configuration: configuration
        )

        if generatedRun.succeeded {
            return """
            Extracted workflow into a reusable script and ran it.
            Script: \(scriptURL.path)

            Script output:
            \(generatedRun.combinedOutput)

            Agent build log:
            \(buildOutput)
            """
        }

        let repairOutput = try await localAgents.run(
            configuration: configuration,
            prompt: repairPrompt(
                context: context,
                script: automationWorkspace.readScript(for: button.id),
                failure: generatedRun.combinedOutput
            ),
            additionalWritableDirectories: [workspaceURL.path]
        )
        automationWorkspace.markScriptExecutable(for: button.id)

        let repairedRun = try await runCachedScript(
            buttonID: button.id,
            values: values,
            configuration: configuration
        )

        guard repairedRun.succeeded else {
            throw WorkflowRunError.commandFailed(
                """
                Agent created a script, attempted one repair, and the script still failed.
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
        buttonID: UUID,
        values: [String: String],
        configuration: AIConfiguration
    ) async throws -> CommandLineResult {
        automationWorkspace.markScriptExecutable(for: buttonID)
        return try await commandLine.run(
            executableURL: URL(filePath: "/bin/zsh"),
            arguments: [automationWorkspace.scriptURL(for: buttonID).path],
            currentDirectoryURL: URL(filePath: normalizedWorkingDirectory(configuration.workingDirectory)),
            environment: scriptEnvironment(values: values, configuration: configuration)
        )
    }

    private func scriptEnvironment(values: [String: String], configuration: AIConfiguration) -> [String: String] {
        var environment = ProcessInfo.processInfo.environment
        environment["BUTTON_WORKING_DIRECTORY"] = normalizedWorkingDirectory(configuration.workingDirectory)

        for (key, value) in values {
            environment["BUTTON_INPUT_\(environmentKey(key))"] = value
        }

        return environment
    }

    private func buttonContext(
        button: ActionButton,
        prompt: String,
        values: [String: String],
        configuration: AIConfiguration,
        scriptURL: URL
    ) -> String {
        let inputLines = values
            .sorted { $0.key < $1.key }
            .map { "- \($0.key): \($0.value)" }
            .joined(separator: "\n")

        return """
        Button: \(button.title)
        Button ID: \(button.id.uuidString)
        Goal: \(button.taskDescription)
        Workflow instruction:
        \(prompt)

        Inputs:
        \(inputLines.isEmpty ? "- none" : inputLines)

        Reusable script path:
        \(scriptURL.path)

        Working directory:
        \(normalizedWorkingDirectory(configuration.workingDirectory))

        Environment inputs:
        \(environmentDocumentation(values: values))
        """
    }

    private func buildScriptPrompt(context: String) -> String {
        """
        You are running a Buttons self-healing workflow.

        The button must become cheaper each time it is clicked. Extract this repetitive workflow into a reusable zsh script at the exact path below, then make it executable.

        Requirements:
        - Create or overwrite the script at the reusable script path.
        - The script must be zsh.
        - Use the BUTTON_INPUT_* environment variables for run-time inputs.
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

    private func environmentDocumentation(values: [String: String]) -> String {
        if values.isEmpty {
            return "- none"
        }

        return values.keys
            .sorted()
            .map { "- BUTTON_INPUT_\(environmentKey($0))" }
            .joined(separator: "\n")
    }

    private func environmentKey(_ key: String) -> String {
        let allowed = CharacterSet.alphanumerics
        let scalars = key.unicodeScalars.map { scalar in
            allowed.contains(scalar) ? Character(scalar).uppercased() : "_"
        }
        let joined = scalars.joined()
        return joined.isEmpty ? "VALUE" : joined
    }

    private func normalizedWorkingDirectory(_ path: String) -> String {
        let trimmedPath = path.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedPath.isEmpty else {
            return AIConfiguration.defaultWorkingDirectory
        }

        if trimmedPath == "~" {
            return FileManager.default.homeDirectoryForCurrentUser.path
        }

        if trimmedPath.hasPrefix("~/") {
            return FileManager.default.homeDirectoryForCurrentUser
                .appending(path: String(trimmedPath.dropFirst(2)))
                .path
        }

        return trimmedPath
    }
}
