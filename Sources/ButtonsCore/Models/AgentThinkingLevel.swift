import Foundation

public enum AgentThinkingLevel: String, Codable, CaseIterable, Equatable, Identifiable, Sendable {
    case low
    case medium
    case high
    case xhigh
    case max

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .low:
            "Low"
        case .medium:
            "Medium"
        case .high:
            "High"
        case .xhigh:
            "X-High"
        case .max:
            "Max"
        }
    }

    public var codexValue: String {
        rawValue
    }

    public var claudeValue: String {
        rawValue
    }
}
