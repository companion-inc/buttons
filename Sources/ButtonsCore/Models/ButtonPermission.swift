import Foundation

public struct ButtonPermission: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var title: String
    public var detail: String

    public init(id: UUID = UUID(), title: String, detail: String = "") {
        self.id = id
        self.title = title
        self.detail = detail
    }
}
