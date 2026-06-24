import Foundation

public struct WorkflowStep: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var title: String
    public var kind: WorkflowStepKind
    public var value: String
    public var aiConfiguration: AIConfiguration?

    public init(
        id: UUID = UUID(),
        title: String,
        kind: WorkflowStepKind,
        value: String,
        aiConfiguration: AIConfiguration? = nil
    ) {
        self.id = id
        self.title = title
        self.kind = kind
        self.value = value
        self.aiConfiguration = aiConfiguration
    }

    public var requiresApproval: Bool {
        kind.requiresApproval || (aiConfiguration?.executionMode.requiresApproval ?? false)
    }
}
