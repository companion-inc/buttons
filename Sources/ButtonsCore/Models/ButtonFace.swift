import Foundation

public struct ButtonFace: Codable, Equatable, Sendable {
    public var symbolName: String
    public var color: ButtonColor
    public var surface: ButtonSurface

    public init(
        symbolName: String = "button.programmable",
        color: ButtonColor = .poppy,
        surface: ButtonSurface = .raised
    ) {
        self.symbolName = symbolName
        self.color = color
        self.surface = surface
    }
}
