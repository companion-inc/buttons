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

    public func workspaceURL(for button: ActionButton) -> URL {
        workspaceURL(forSlug: button.slug)
    }

    public func workspaceURL(forSlug slug: String) -> URL {
        rootURL.appending(path: ButtonWorkspaceSlug.make(from: slug), directoryHint: .isDirectory)
    }

    public func automationURL(for button: ActionButton) -> URL {
        workspaceURL(for: button).appending(path: "automation", directoryHint: .isDirectory)
    }

    public func runnerURL(for button: ActionButton) -> URL {
        automationURL(for: button).appending(path: "run.zsh")
    }

    public func contextURL(for button: ActionButton) -> URL {
        workspaceURL(for: button).appending(path: "button.md")
    }

    public func skillsURL(for button: ActionButton) -> URL {
        workspaceURL(for: button).appending(path: "skills", directoryHint: .isDirectory)
    }

    public func logsURL(for button: ActionButton) -> URL {
        workspaceURL(for: button).appending(path: "logs", directoryHint: .isDirectory)
    }

    public func agentURL(for button: ActionButton) -> URL {
        workspaceURL(for: button).appending(path: "agent", directoryHint: .isDirectory)
    }

    public func ensureWorkspace(for button: ActionButton) throws -> URL {
        let workspaceURL = workspaceURL(for: button)
        try FileManager.default.createDirectory(at: automationURL(for: button), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: skillsURL(for: button), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: logsURL(for: button), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: agentURL(for: button), withIntermediateDirectories: true)
        try writeSkillsReadmeIfNeeded(for: button)
        return workspaceURL
    }

    public func automationExists(for button: ActionButton) -> Bool {
        FileManager.default.fileExists(atPath: runnerURL(for: button).path)
            || FileManager.default.fileExists(atPath: legacyRunnerURL(for: button).path)
    }

    public func readAutomation(for button: ActionButton) -> String {
        if let current = try? String(contentsOf: runnerURL(for: button), encoding: .utf8) {
            return current
        }

        return (try? String(contentsOf: legacyRunnerURL(for: button), encoding: .utf8)) ?? ""
    }

    public func markAutomationExecutable(for button: ActionButton) {
        for url in [runnerURL(for: button), legacyRunnerURL(for: button)] where FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.setAttributes(
                [.posixPermissions: 0o755],
                ofItemAtPath: url.path
            )
        }
    }

    public func writeContext(_ context: String, for button: ActionButton) throws {
        try context.write(to: contextURL(for: button), atomically: true, encoding: .utf8)
    }

    public func writeRunLog(_ receipt: ButtonRunReceipt, for button: ActionButton) throws {
        _ = try ensureWorkspace(for: button)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let timestamp = formatter.string(from: receipt.startedAt)
            .replacingOccurrences(of: ":", with: "-")
        let logURL = logsURL(for: button)
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

    private func writeSkillsReadmeIfNeeded(for button: ActionButton) throws {
        let readmeURL = skillsURL(for: button).appending(path: "README.md")
        guard !FileManager.default.fileExists(atPath: readmeURL.path) else {
            return
        }

        let body = """
        # Button Skills

        Put reusable notes, procedures, and helper instructions for this button here.
        The self-healing agent can read and update this folder when a button gets cheaper or more reliable.
        """
        try body.write(to: readmeURL, atomically: true, encoding: .utf8)
    }

    private func legacyRunnerURL(for button: ActionButton) -> URL {
        workspaceURL(for: button)
            .appending(path: "scripts", directoryHint: .isDirectory)
            .appending(path: "run.zsh")
    }
}
