import Foundation

public actor ShellCommandExecutor {
    private let executor: CommandLineExecutor

    public init(executor: CommandLineExecutor = CommandLineExecutor()) {
        self.executor = executor
    }

    public func run(_ command: String) async throws -> String {
        let result = try await executor.run(
            executableURL: URL(filePath: "/bin/zsh"),
            arguments: ["-lc", command]
        )

        guard result.succeeded else {
            throw WorkflowRunError.commandFailed(result.combinedOutput)
        }

        return result.output
    }
}
