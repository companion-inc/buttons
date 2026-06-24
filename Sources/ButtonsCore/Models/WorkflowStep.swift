import Foundation

public struct WorkflowStep: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var title: String
    public var kind: WorkflowStepKind
    public var value: String

    public init(
        id: UUID = UUID(),
        title: String,
        kind: WorkflowStepKind,
        value: String
    ) {
        self.id = id
        self.title = title
        self.kind = kind
        self.value = value
    }
}
