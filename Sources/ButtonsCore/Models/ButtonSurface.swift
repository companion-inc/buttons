import Foundation

public enum ButtonSurface: String, Codable, CaseIterable, Equatable, Identifiable, Sendable {
    case raised
    case rubber
    case metal
    case glass
    case terminal

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .raised:
            "Raised"
        case .rubber:
            "Rubber"
        case .metal:
            "Metal"
        case .glass:
            "Glass"
        case .terminal:
            "Terminal"
        }
    }
}
