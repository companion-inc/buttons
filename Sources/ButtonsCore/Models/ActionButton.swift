import Foundation

public struct ActionButton: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var title: String
    public var subtitle: String
    public var taskDescription: String
    public var face: ButtonFace
    public var workflow: ButtonWorkflow
    public var approvalPolicy: ApprovalPolicy
    public var permissions: [ButtonPermission]
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        title: String,
        subtitle: String,
        taskDescription: String,
        face: ButtonFace,
        workflow: ButtonWorkflow,
        approvalPolicy: ApprovalPolicy = .automatic,
        permissions: [ButtonPermission] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.taskDescription = taskDescription
        self.face = face
        self.workflow = workflow
        self.approvalPolicy = approvalPolicy
        self.permissions = permissions
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public var needsApproval: Bool {
        switch approvalPolicy {
        case .always:
            return true
        case .never:
            return workflow.steps.contains { $0.kind.requiresApproval }
        case .automatic:
            return workflow.steps.contains { $0.kind.requiresApproval }
        }
    }

    public func updated(now: Date = Date()) -> ActionButton {
        var copy = self
        copy.updatedAt = now
        return copy
    }
}
