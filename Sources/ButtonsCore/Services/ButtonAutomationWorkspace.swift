import Foundation

public struct ButtonAutomationWorkspace: Sendable {
    public var rootURL: URL

    public init(rootURL: URL) {
        self.rootURL = rootURL
    }

    public static func production() -> ButtonAutomationWorkspace {
        let supportURL = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0]
        return ButtonAutomationWorkspace(
            rootURL: supportURL
                .appending(path: "Buttons", directoryHint: .isDirectory)
                .appending(path: "Automations", directoryHint: .isDirectory)
        )
    }

    public func workspaceURL(for buttonID: UUID) -> URL {
        rootURL.appending(path: buttonID.uuidString, directoryHint: .isDirectory)
    }

    public func scriptURL(for buttonID: UUID) -> URL {
        workspaceURL(for: buttonID).appending(path: "run.zsh")
    }

    public func contextURL(for buttonID: UUID) -> URL {
        workspaceURL(for: buttonID).appending(path: "button.md")
    }

    public func ensureWorkspace(for buttonID: UUID) throws -> URL {
        let workspaceURL = workspaceURL(for: buttonID)
        try FileManager.default.createDirectory(at: workspaceURL, withIntermediateDirectories: true)
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
}
