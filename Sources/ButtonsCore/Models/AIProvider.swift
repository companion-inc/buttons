import Foundation

public enum AIProvider: String, Codable, CaseIterable, Equatable, Hashable, Identifiable, Sendable {
    case codex
    case claudeCode

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .codex:
            "Codex"
        case .claudeCode:
            "Claude Code"
        }
    }

    public var shortTitle: String {
        return switch self {
        case .codex:
            "Codex"
        case .claudeCode:
            "Claude"
        }
    }

    public var commandName: String {
        switch self {
        case .codex:
            "codex"
        case .claudeCode:
            "claude"
        }
    }

    public var loginStatusArguments: [String] {
        switch self {
        case .codex:
            ["login", "status"]
        case .claudeCode:
            ["auth", "status"]
        }
    }

    public var executableCandidates: [String] {
        let home = FileManager.default.homeDirectoryForCurrentUser.path

        return switch self {
        case .codex:
            [
                "\(home)/.npm-global/bin/codex",
                "/opt/homebrew/bin/codex",
                "/usr/local/bin/codex",
            ]
        case .claudeCode:
            [
                "\(home)/.local/bin/claude",
                "/opt/homebrew/bin/claude",
                "/usr/local/bin/claude",
            ]
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)

        switch rawValue {
        case "codex", "openAI":
            self = .codex
        case "claudeCode", "anthropic":
            self = .claudeCode
        default:
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unknown agent provider \(rawValue)."
            )
        }
    }
}
