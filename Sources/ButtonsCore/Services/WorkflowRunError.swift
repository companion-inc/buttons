import Foundation

public enum WorkflowRunError: Error, Equatable, LocalizedError, Sendable {
    case invalidURL(String)
    case commandFailed(String)
    case missingShortcutName

    public var errorDescription: String? {
        switch self {
        case .invalidURL(let value):
            "Invalid URL: \(value)"
        case .commandFailed(let output):
            output.isEmpty ? "Command failed." : output
        case .missingShortcutName:
            "Shortcut name is missing."
        }
    }
}
