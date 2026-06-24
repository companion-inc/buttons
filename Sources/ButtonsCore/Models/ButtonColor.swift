import Foundation

public enum ButtonColor: String, Codable, CaseIterable, Equatable, Identifiable, Sendable {
    case poppy
    case cobalt
    case mint
    case graphite
    case lemon
    case rose
    case ocean
    case paper

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .poppy:
            "Poppy"
        case .cobalt:
            "Cobalt"
        case .mint:
            "Mint"
        case .graphite:
            "Graphite"
        case .lemon:
            "Lemon"
        case .rose:
            "Rose"
        case .ocean:
            "Ocean"
        case .paper:
            "Paper"
        }
    }

    public var hex: String {
        switch self {
        case .poppy:
            "#F25A3C"
        case .cobalt:
            "#286BE8"
        case .mint:
            "#26B99A"
        case .graphite:
            "#26282E"
        case .lemon:
            "#F0C83B"
        case .rose:
            "#E85D89"
        case .ocean:
            "#14A7C8"
        case .paper:
            "#F2ECE3"
        }
    }

    public var foregroundHex: String {
        switch self {
        case .lemon, .paper:
            "#171717"
        case .poppy, .cobalt, .mint, .graphite, .rose, .ocean:
            "#FFFFFF"
        }
    }
}
