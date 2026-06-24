import Foundation

public enum AIExecutionMode: String, Codable, CaseIterable, Equatable, Identifiable, Sendable {
    case replyOnly
    case workspaceWrite
    case dangerouslyRun

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .replyOnly:
            "Answer only"
        case .workspaceWrite:
            "Workspace write"
        case .dangerouslyRun:
            "Dangerous run"
        }
    }

    public var requiresApproval: Bool {
        switch self {
        case .replyOnly, .workspaceWrite:
            false
        case .dangerouslyRun:
            true
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)

        switch rawValue {
        case "replyOnly", "copyReply":
            self = .replyOnly
        case "workspaceWrite":
            self = .workspaceWrite
        case "dangerouslyRun", "dangerouslyRunShell":
            self = .dangerouslyRun
        default:
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unknown agent execution mode \(rawValue)."
            )
        }
    }
}
