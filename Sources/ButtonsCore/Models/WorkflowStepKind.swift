import Foundation

public enum WorkflowStepKind: String, Codable, CaseIterable, Equatable, Identifiable, Sendable {
    case openURL
    case copyText
    case runShortcut
    case runShellCommand
    case showMessage

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .openURL:
            "Open URL"
        case .copyText:
            "Copy text"
        case .runShortcut:
            "Run Shortcut"
        case .runShellCommand:
            "Run command"
        case .showMessage:
            "Show message"
        }
    }

    public var valueLabel: String {
        switch self {
        case .openURL:
            "URL"
        case .copyText:
            "Text"
        case .runShortcut:
            "Shortcut"
        case .runShellCommand:
            "Command"
        case .showMessage:
            "Message"
        }
    }

    public var requiresApproval: Bool {
        switch self {
        case .runShortcut, .runShellCommand:
            true
        case .openURL, .copyText, .showMessage:
            false
        }
    }
}
