@testable import ButtonsCore
import Foundation
import Testing

@Suite("Command line executor")
struct CommandLineExecutorTests {
    @Test("Cancellation terminates the running process")
    func cancellationTerminatesRunningProcess() async throws {
        let executor = CommandLineExecutor()
        let task = Task {
            try await executor.run(
                executableURL: URL(filePath: "/bin/sleep"),
                arguments: ["10"]
            )
        }

        try await Task.sleep(for: .milliseconds(100))
        task.cancel()

        do {
            _ = try await task.value
            Issue.record("Expected the sleeping process to be canceled.")
        } catch is CancellationError {
            return
        }
    }
}
