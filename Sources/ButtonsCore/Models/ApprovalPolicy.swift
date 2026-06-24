import Foundation

public enum ApprovalPolicy: String, Codable, CaseIterable, Equatable, Identifiable, Sendable {
    case automatic
    case always
    case never

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .automatic:
            "Ask first"
        case .always:
            "Always ask"
        case .never:
            "Run immediately"
        }
    }
}
