import Foundation

public enum ApprovalPolicy: String, Codable, CaseIterable, Equatable, Identifiable, Sendable {
    case automatic
    case always
    case never

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .automatic:
            "Confirm risky"
        case .always:
            "Always confirm"
        case .never:
            "Run immediately"
        }
    }
}
