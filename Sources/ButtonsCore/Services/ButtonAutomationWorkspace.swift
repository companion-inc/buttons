import Foundation

public struct ButtonAutomationWorkspace: Sendable {
    public var rootURL: URL

    public init(rootURL: URL) {
        self.rootURL = rootURL
    }

    public static var homeURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appending(path: ".buttons", directoryHint: .isDirectory)
    }

    public static func production() -> ButtonAutomationWorkspace {
        return ButtonAutomationWorkspace(
            rootURL: homeURL.appending(path: "buttons", directoryHint: .isDirectory)
        )
    }

    public func workspaceURL(for buttonID: UUID) -> URL {
        rootURL.appending(path: buttonID.uuidString, directoryHint: .isDirectory)
    }

    public func scriptsURL(for buttonID: UUID) -> URL {
        workspaceURL(for: buttonID).appending(path: "scripts", directoryHint: .isDirectory)
    }

    public func scriptURL(for buttonID: UUID) -> URL {
        scriptsURL(for: buttonID).appending(path: "run.zsh")
    }

    public func contextURL(for buttonID: UUID) -> URL {
        workspaceURL(for: buttonID).appending(path: "button.md")
    }

    public func skillsURL(for buttonID: UUID) -> URL {
        workspaceURL(for: buttonID).appending(path: "skills", directoryHint: .isDirectory)
    }

    public func logsURL(for buttonID: UUID) -> URL {
        workspaceURL(for: buttonID).appending(path: "logs", directoryHint: .isDirectory)
    }

    public func agentURL(for buttonID: UUID) -> URL {
        workspaceURL(for: buttonID).appending(path: "agent", directoryHint: .isDirectory)
    }

    public func ensureWorkspace(for buttonID: UUID) throws -> URL {
        let workspaceURL = workspaceURL(for: buttonID)
        try FileManager.default.createDirectory(at: scriptsURL(for: buttonID), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: skillsURL(for: buttonID), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: logsURL(for: buttonID), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: agentURL(for: buttonID), withIntermediateDirectories: true)
        try writeSkillsReadmeIfNeeded(for: buttonID)
        return workspaceURL
    }

    public func scriptExists(for buttonID: UUID) -> Bool {
        FileManager.default.fileExists(atPath: scriptURL(for: buttonID).path)
    }

    public func readScript(for buttonID: UUID) -> String {
        (try? String(contentsOf: scriptURL(for: buttonID), encoding: .utf8)) ?? ""
    }

    public func markScriptExecutable(for buttonID: UUID) {
        try? FileManager.default.setAttributes(
            [.posixPermissions: 0o755],
            ofItemAtPath: scriptURL(for: buttonID).path
        )
    }

    public func writeContext(_ context: String, for buttonID: UUID) throws {
        try context.write(to: contextURL(for: buttonID), atomically: true, encoding: .utf8)
    }

    public func writeRunLog(_ receipt: ButtonRunReceipt) throws {
        _ = try ensureWorkspace(for: receipt.buttonID)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let timestamp = formatter.string(from: receipt.startedAt)
            .replacingOccurrences(of: ":", with: "-")
        let logURL = logsURL(for: receipt.buttonID)
            .appending(path: "\(timestamp)-\(receipt.id.uuidString).md")
        let body = """
        # \(receipt.buttonTitle)

        Status: \(receipt.status.rawValue)
        Started: \(formatter.string(from: receipt.startedAt))
        Finished: \(formatter.string(from: receipt.finishedAt))
        Summary: \(receipt.summary)

        ```text
        \(receipt.output)
        ```
        """
        try body.write(to: logURL, atomically: true, encoding: .utf8)
    }

    private func writeSkillsReadmeIfNeeded(for buttonID: UUID) throws {
        let readmeURL = skillsURL(for: buttonID).appending(path: "README.md")
        guard !FileManager.default.fileExists(atPath: readmeURL.path) else {
            return
        }

        let body = """
        # Button Skills

        Put reusable notes, procedures, and helper instructions for this button here.
        The self-healing agent can read and update this folder when a workflow gets cheaper or more reliable.
        """
        try body.write(to: readmeURL, atomically: true, encoding: .utf8)
    }
}
