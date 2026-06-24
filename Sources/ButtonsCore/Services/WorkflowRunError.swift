import Foundation

public enum WorkflowRunError: Error, Equatable, LocalizedError, Sendable {
    case invalidURL(String)
    case commandFailed(String)
    case missingShortcutName
    case missingAIConfiguration
    case localAgentUnavailable(AIProvider, [String])
    case localAgentFailed(AIProvider, String)

    public var errorDescription: String? {
        switch self {
        case .invalidURL(let value):
            "Invalid URL: \(value)"
        case .commandFailed(let output):
            output.isEmpty ? "Command failed." : output
        case .missingShortcutName:
            "Shortcut name is missing."
        case .missingAIConfiguration:
            "Agent task is missing local CLI configuration."
        case .localAgentUnavailable(let provider, let candidates):
            "\(provider.shortTitle) command was not found. Checked: \(candidates.joined(separator: ", "))."
        case .localAgentFailed(let provider, let output):
            output.isEmpty ? "\(provider.shortTitle) command failed." : output
        }
    }
}
