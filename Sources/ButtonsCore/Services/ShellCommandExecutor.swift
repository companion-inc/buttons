import Foundation

public actor ShellCommandExecutor {
    public init() {}

    public func run(_ command: String) throws -> String {
        let process = Process()
        let outputPipe = Pipe()
        let errorPipe = Pipe()

        process.executableURL = URL(filePath: "/bin/zsh")
        process.arguments = ["-lc", command]
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        try process.run()
        process.waitUntilExit()

        let output = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let error = errorPipe.fileHandleForReading.readDataToEndOfFile()
        let outputText = String(data: output, encoding: .utf8) ?? ""
        let errorText = String(data: error, encoding: .utf8) ?? ""

        guard process.terminationStatus == 0 else {
            throw WorkflowRunError.commandFailed(errorText.isEmpty ? outputText : errorText)
        }

        return outputText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
