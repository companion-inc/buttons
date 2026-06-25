import Foundation

public actor CommandLineExecutor {
    public init() {}

    public func run(
        executableURL: URL,
        arguments: [String],
        currentDirectoryURL: URL? = nil,
        environment: [String: String]? = nil
    ) async throws -> CommandLineResult {
        try Task.checkCancellation()

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

        let cancellation = ProcessCancellationHandle(process: process)
        let outputReader = CommandOutputReader(
            process: process,
            outputURL: outputURL,
            errorURL: errorURL,
            outputHandle: outputHandle,
            errorHandle: errorHandle,
            cancellation: cancellation
        )

        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                let guardedContinuation = CommandLineContinuation(continuation)

                process.terminationHandler = { _ in
                    guardedContinuation.resume {
                        try outputReader.result()
                    }
                }

                do {
                    guard !cancellation.isCancelled else {
                        throw CancellationError()
                    }
                    try process.run()
                    if cancellation.isCancelled {
                        cancellation.terminate()
                    }
                } catch {
                    guardedContinuation.resume(throwing: error)
                }
            }
        } onCancel: {
            cancellation.cancel()
        }
    }
}

private final class ProcessCancellationHandle: @unchecked Sendable {
    private let lock = NSLock()
    private let process: Process
    private var cancelled = false

    init(process: Process) {
        self.process = process
    }

    var isCancelled: Bool {
        lock.withLock {
            cancelled
        }
    }

    func cancel() {
        lock.withLock {
            cancelled = true
            terminateIfRunning()
        }
    }

    func terminate() {
        lock.withLock {
            terminateIfRunning()
        }
    }

    private func terminateIfRunning() {
        guard process.isRunning else {
            return
        }

        process.terminate()
    }
}

private final class CommandOutputReader: @unchecked Sendable {
    private let process: Process
    private let outputURL: URL
    private let errorURL: URL
    private let outputHandle: FileHandle
    private let errorHandle: FileHandle
    private let cancellation: ProcessCancellationHandle

    init(
        process: Process,
        outputURL: URL,
        errorURL: URL,
        outputHandle: FileHandle,
        errorHandle: FileHandle,
        cancellation: ProcessCancellationHandle
    ) {
        self.process = process
        self.outputURL = outputURL
        self.errorURL = errorURL
        self.outputHandle = outputHandle
        self.errorHandle = errorHandle
        self.cancellation = cancellation
    }

    func result() throws -> CommandLineResult {
        try? outputHandle.close()
        try? errorHandle.close()

        if cancellation.isCancelled {
            throw CancellationError()
        }

        let output = try String(contentsOf: outputURL, encoding: .utf8)
        let error = try String(contentsOf: errorURL, encoding: .utf8)

        return CommandLineResult(
            exitCode: process.terminationStatus,
            output: output.trimmingCharacters(in: .whitespacesAndNewlines),
            error: error.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }
}

private final class CommandLineContinuation: @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<CommandLineResult, Error>?

    init(_ continuation: CheckedContinuation<CommandLineResult, Error>) {
        self.continuation = continuation
    }

    func resume(returning result: CommandLineResult) {
        takeContinuation()?.resume(returning: result)
    }

    func resume(throwing error: Error) {
        takeContinuation()?.resume(throwing: error)
    }

    func resume(_ result: () throws -> CommandLineResult) {
        do {
            resume(returning: try result())
        } catch {
            resume(throwing: error)
        }
    }

    private func takeContinuation() -> CheckedContinuation<CommandLineResult, Error>? {
        lock.withLock {
            let current = continuation
            continuation = nil
            return current
        }
    }
}
