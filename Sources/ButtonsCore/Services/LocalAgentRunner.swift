import Foundation

public actor LocalAgentRunner {
    private let executor: CommandLineExecutor

    public init(executor: CommandLineExecutor = CommandLineExecutor()) {
        self.executor = executor
    }

    public func status(for provider: AIProvider) async -> LocalAgentStatus {
        do {
            let executableURL = try await executableURL(for: provider)
            let result = try await executor.run(
                executableURL: executableURL,
                arguments: provider.loginStatusArguments,
                environment: agentEnvironment()
            )
            let details = result.combinedOutput.isEmpty ? "\(provider.shortTitle) is authenticated." : result.combinedOutput

            return LocalAgentStatus(
                provider: provider,
                isInstalled: true,
                isAuthenticated: result.succeeded,
                executablePath: executableURL.path,
                details: details
            )
        } catch WorkflowRunError.localAgentUnavailable {
            return LocalAgentStatus(
                provider: provider,
                isInstalled: false,
                isAuthenticated: false,
                executablePath: nil,
                details: "\(provider.commandName) is not installed in the expected local paths."
            )
        } catch {
            return LocalAgentStatus(
                provider: provider,
                isInstalled: true,
                isAuthenticated: false,
                executablePath: nil,
                details: error.localizedDescription
            )
        }
    }

    public func run(
        configuration: AIConfiguration,
        prompt: String,
        additionalWritableDirectories: [String] = [],
        environmentOverrides: [String: String] = [:]
    ) async throws -> String {
        let executableURL = try await executableURL(for: configuration.provider)

        switch configuration.provider {
        case .codex:
            return try await runCodex(
                executableURL: executableURL,
                configuration: configuration,
                prompt: prompt,
                additionalWritableDirectories: additionalWritableDirectories,
                environmentOverrides: environmentOverrides
            )
        case .claudeCode:
            return try await runClaude(
                executableURL: executableURL,
                configuration: configuration,
                prompt: prompt,
                additionalWritableDirectories: additionalWritableDirectories,
                environmentOverrides: environmentOverrides
            )
        }
    }

    static func codexArguments(
        configuration: AIConfiguration,
        prompt: String,
        lastMessagePath: String,
        additionalWritableDirectories: [String] = []
    ) -> [String] {
        var arguments = [
            "exec",
            "--cd",
            normalizedWorkingDirectory(configuration.workingDirectory),
            "--skip-git-repo-check",
            "--ephemeral",
            "--output-last-message",
            lastMessagePath,
            "-c",
            "model_reasoning_effort=\"\(configuration.thinkingLevel.codexValue)\"",
        ]

        for directory in additionalWritableDirectories.map(normalizedWorkingDirectory) {
            arguments.append(contentsOf: ["--add-dir", directory])
        }

        appendModelOverride(configuration.model, to: &arguments)

        switch configuration.executionMode {
        case .replyOnly:
            arguments.append(contentsOf: ["--sandbox", "read-only"])
        case .workspaceWrite:
            arguments.append(contentsOf: ["--sandbox", "workspace-write"])
        case .dangerouslyRun:
            arguments.append(contentsOf: [
                "--sandbox",
                "danger-full-access",
                "--dangerously-bypass-approvals-and-sandbox",
            ])
        }

        arguments.append(fullPrompt(configuration: configuration, prompt: prompt))
        return arguments
    }

    static func claudeArguments(
        configuration: AIConfiguration,
        prompt: String,
        additionalWritableDirectories: [String] = []
    ) -> [String] {
        var arguments = [
            "-p",
            "--output-format",
            "text",
            "--no-session-persistence",
            "--effort",
            configuration.thinkingLevel.claudeValue,
        ]

        for directory in ([configuration.workingDirectory] + additionalWritableDirectories).map(normalizedWorkingDirectory) {
            arguments.append(contentsOf: ["--add-dir", directory])
        }

        appendModelOverride(configuration.model, to: &arguments)

        switch configuration.executionMode {
        case .replyOnly:
            arguments.append(contentsOf: ["--permission-mode", "plan"])
        case .workspaceWrite:
            arguments.append(contentsOf: ["--permission-mode", "auto"])
        case .dangerouslyRun:
            arguments.append(contentsOf: [
                "--permission-mode",
                "bypassPermissions",
                "--dangerously-skip-permissions",
            ])
        }

        arguments.append(fullPrompt(configuration: configuration, prompt: prompt))
        return arguments
    }

    private func runCodex(
        executableURL: URL,
        configuration: AIConfiguration,
        prompt: String,
        additionalWritableDirectories: [String],
        environmentOverrides: [String: String]
    ) async throws -> String {
        let lastMessageURL = FileManager.default.temporaryDirectory.appending(path: "ButtonsCodex-\(UUID().uuidString).txt")
        defer {
            try? FileManager.default.removeItem(at: lastMessageURL)
        }

        let result = try await executor.run(
            executableURL: executableURL,
            arguments: Self.codexArguments(
                configuration: configuration,
                prompt: prompt,
                lastMessagePath: lastMessageURL.path,
                additionalWritableDirectories: additionalWritableDirectories
            ),
            currentDirectoryURL: URL(filePath: Self.normalizedWorkingDirectory(configuration.workingDirectory)),
            environment: agentEnvironment(overrides: environmentOverrides)
        )

        let lastMessage = (try? String(contentsOf: lastMessageURL, encoding: .utf8))?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if result.succeeded {
            return lastMessage?.isEmpty == false ? lastMessage! : result.output
        }

        throw WorkflowRunError.localAgentFailed(configuration.provider, result.combinedOutput)
    }

    private func runClaude(
        executableURL: URL,
        configuration: AIConfiguration,
        prompt: String,
        additionalWritableDirectories: [String],
        environmentOverrides: [String: String]
    ) async throws -> String {
        let result = try await executor.run(
            executableURL: executableURL,
            arguments: Self.claudeArguments(
                configuration: configuration,
                prompt: prompt,
                additionalWritableDirectories: additionalWritableDirectories
            ),
            currentDirectoryURL: URL(filePath: Self.normalizedWorkingDirectory(configuration.workingDirectory)),
            environment: agentEnvironment(overrides: environmentOverrides)
        )

        guard result.succeeded else {
            throw WorkflowRunError.localAgentFailed(configuration.provider, result.combinedOutput)
        }

        return result.output.isEmpty ? result.error : result.output
    }

    private func executableURL(for provider: AIProvider) async throws -> URL {
        let fileManager = FileManager.default

        for candidate in provider.executableCandidates where fileManager.isExecutableFile(atPath: candidate) {
            return URL(filePath: candidate)
        }

        if let whichURL = try? await which(provider.commandName) {
            return whichURL
        }

        throw WorkflowRunError.localAgentUnavailable(provider, provider.executableCandidates)
    }

    private func which(_ commandName: String) async throws -> URL? {
        let result = try await executor.run(
            executableURL: URL(filePath: "/usr/bin/which"),
            arguments: [commandName],
            environment: agentEnvironment()
        )

        guard result.succeeded, !result.output.isEmpty else {
            return nil
        }

        return URL(filePath: result.output.components(separatedBy: .newlines).first ?? result.output)
    }

    private func agentEnvironment(overrides: [String: String] = [:]) -> [String: String] {
        var environment = ProcessInfo.processInfo.environment
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let defaultPath = [
            "\(home)/.npm-global/bin",
            "\(home)/.local/bin",
            "/opt/homebrew/bin",
            "/usr/local/bin",
            "/usr/bin",
            "/bin",
            "/usr/sbin",
            "/sbin",
        ].joined(separator: ":")

        if let existingPath = environment["PATH"], !existingPath.isEmpty {
            environment["PATH"] = "\(defaultPath):\(existingPath)"
        } else {
            environment["PATH"] = defaultPath
        }

        for (key, value) in overrides {
            environment[key] = value
        }

        return environment
    }

    private static func appendModelOverride(_ model: String, to arguments: inout [String]) {
        let trimmedModel = model.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedModel.isEmpty else {
            return
        }

        arguments.append(contentsOf: ["--model", trimmedModel])
    }

    private static func fullPrompt(configuration: AIConfiguration, prompt: String) -> String {
        let trimmedSystemPrompt = configuration.systemPrompt.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedSystemPrompt.isEmpty else {
            return prompt
        }

        return """
        \(trimmedSystemPrompt)

        Task:
        \(prompt)
        """
    }

    private static func normalizedWorkingDirectory(_ path: String) -> String {
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
