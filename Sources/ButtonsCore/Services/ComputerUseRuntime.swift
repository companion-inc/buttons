import Foundation

public struct ComputerUseRuntime: Sendable {
    public static let helperName = "ButtonsComputerUseRuntime"

    private let executor: CommandLineExecutor
    private let explicitExecutableURL: URL?

    public init(
        executor: CommandLineExecutor = CommandLineExecutor(),
        executableURL: URL? = nil
    ) {
        self.executor = executor
        self.explicitExecutableURL = executableURL
    }

    public func collect(
        for button: ActionButton,
        workspace: ButtonAutomationWorkspace
    ) async -> ComputerUseContextSnapshot {
        guard let executableURL = executableURL() else {
            return writeUnavailableContext(
                for: button,
                workspace: workspace,
                reason: "\(Self.helperName) is not installed beside Buttons."
            )
        }

        do {
            let result = try await executor.run(
                executableURL: executableURL,
                arguments: [
                    "snapshot",
                    "--root",
                    workspace.rootURL.path,
                    "--slug",
                    button.slug,
                    "--title",
                    button.title,
                    "--category",
                    button.category,
                ],
                environment: runtimeEnvironment()
            )

            guard result.succeeded else {
                return writeUnavailableContext(
                    for: button,
                    workspace: workspace,
                    reason: result.combinedOutput.isEmpty ? "\(Self.helperName) exited with code \(result.exitCode)." : result.combinedOutput
                )
            }

            let output = result.combinedOutput
            return ComputerUseContextSnapshot(
                contextURL: workspace.computerUseContextURL(for: button),
                summary: output.isEmpty ? "Computer use runtime refreshed context." : output
            )
        } catch {
            return writeUnavailableContext(
                for: button,
                workspace: workspace,
                reason: error.localizedDescription
            )
        }
    }

    public func executableURL() -> URL? {
        let fileManager = FileManager.default
        let candidates = executableCandidates()

        return candidates.first { candidate in
            fileManager.isExecutableFile(atPath: candidate.path)
        }
    }

    private func executableCandidates() -> [URL] {
        if let explicitExecutableURL {
            return [explicitExecutableURL]
        }

        var candidates: [URL] = []

        let bundleURL = Bundle.main.bundleURL
        candidates.append(
            bundleURL
                .appending(path: "Contents", directoryHint: .isDirectory)
                .appending(path: "Helpers", directoryHint: .isDirectory)
                .appending(path: Self.helperName)
        )

        if let executableDirectory = Bundle.main.executableURL?.deletingLastPathComponent() {
            candidates.append(executableDirectory.appending(path: Self.helperName))
            candidates.append(
                executableDirectory
                    .deletingLastPathComponent()
                    .appending(path: "Helpers", directoryHint: .isDirectory)
                    .appending(path: Self.helperName)
            )
        }

        return candidates
    }

    private func runtimeEnvironment() -> [String: String] {
        var environment = ProcessInfo.processInfo.environment
        environment["BUTTONS_HOST_BUNDLE_IDENTIFIER"] = Bundle.main.bundleIdentifier ?? "ai.companion.buttons"
        return environment
    }

    private func writeUnavailableContext(
        for button: ActionButton,
        workspace: ButtonAutomationWorkspace,
        reason: String
    ) -> ComputerUseContextSnapshot {
        let contextURL = workspace.computerUseContextURL(for: button)
        let computerUseURL = workspace.computerUseURL(for: button)
        _ = try? workspace.ensureWorkspace(for: button)

        let body = """
        # Computer Use Context

        Button: \(button.title)
        Captured: \(ISO8601DateFormatter().string(from: Date()))
        Runtime: unavailable

        \(reason)

        Expected helper:
        \(Self.helperName)

        Computer-use directory:
        \(computerUseURL.path)
        """

        try? body.write(to: contextURL, atomically: true, encoding: .utf8)

        return ComputerUseContextSnapshot(
            contextURL: contextURL,
            summary: "Computer use runtime unavailable: \(reason)"
        )
    }
}
