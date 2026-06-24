import Foundation

public actor CommandLineExecutor {
    public init() {}

    public func run(
        executableURL: URL,
        arguments: [String],
        currentDirectoryURL: URL? = nil,
        environment: [String: String]? = nil
    ) throws -> CommandLineResult {
        let fileManager = FileManager.default
        let tempDirectory = fileManager.temporaryDirectory.appending(path: "ButtonsCommand-\(UUID().uuidString)")
        try fileManager.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        defer {
            try? fileManager.removeItem(at: tempDirectory)
        }

        let outputURL = tempDirectory.appending(path: "stdout.txt")
        let errorURL = tempDirectory.appending(path: "stderr.txt")
        fileManager.createFile(atPath: outputURL.path, contents: nil)
        fileManager.createFile(atPath: errorURL.path, contents: nil)

        let outputHandle = try FileHandle(forWritingTo: outputURL)
        let errorHandle = try FileHandle(forWritingTo: errorURL)
        defer {
            try? outputHandle.close()
            try? errorHandle.close()
        }

        let process = Process()
        process.executableURL = executableURL
        process.arguments = arguments
        process.currentDirectoryURL = currentDirectoryURL
        process.environment = environment
        process.standardOutput = outputHandle
        process.standardError = errorHandle

        try process.run()
        process.waitUntilExit()

        try? outputHandle.close()
        try? errorHandle.close()

        let output = try String(contentsOf: outputURL, encoding: .utf8)
        let error = try String(contentsOf: errorURL, encoding: .utf8)

        return CommandLineResult(
            exitCode: process.terminationStatus,
            output: output.trimmingCharacters(in: .whitespacesAndNewlines),
            error: error.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }
}
