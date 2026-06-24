import Foundation

public struct ButtonInputField: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var key: String
    public var label: String
    public var placeholder: String
    public var defaultValue: String

    public init(
        id: UUID = UUID(),
        key: String,
        label: String,
        placeholder: String = "",
        defaultValue: String = ""
    ) {
        self.id = id
        self.key = key
        self.label = label
        self.placeholder = placeholder
        self.defaultValue = defaultValue
    }
}
