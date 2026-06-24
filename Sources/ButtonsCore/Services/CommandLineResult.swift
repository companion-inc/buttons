import Foundation

public struct CommandLineResult: Equatable, Sendable {
    public var exitCode: Int32
    public var output: String
    public var error: String

    public init(exitCode: Int32, output: String, error: String) {
        self.exitCode = exitCode
        self.output = output
        self.error = error
    }

    public var succeeded: Bool {
        exitCode == 0
    }

    public var combinedOutput: String {
        [output, error]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
    }
}
