import Foundation

public struct ActionButton: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var title: String
    public var subtitle: String
    public var category: String
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
        category: String = "General",
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
        self.category = category
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
            return false
        case .automatic:
            return workflow.steps.contains { $0.requiresApproval }
        }
    }

    public var requiresRunConfirmation: Bool {
        approvalPolicy != .never
    }

    public func updated(now: Date = Date()) -> ActionButton {
        var copy = self
        copy.updatedAt = now
        return copy
    }

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case subtitle
        case category
        case taskDescription
        case face
        case workflow
        case approvalPolicy
        case permissions
        case createdAt
        case updatedAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        title = try container.decode(String.self, forKey: .title)
        subtitle = try container.decode(String.self, forKey: .subtitle)
        category = try container.decodeIfPresent(String.self, forKey: .category) ?? "General"
        taskDescription = try container.decode(String.self, forKey: .taskDescription)
        face = try container.decode(ButtonFace.self, forKey: .face)
        workflow = try container.decode(ButtonWorkflow.self, forKey: .workflow)
        approvalPolicy = try container.decodeIfPresent(ApprovalPolicy.self, forKey: .approvalPolicy) ?? .automatic
        permissions = try container.decodeIfPresent([ButtonPermission].self, forKey: .permissions) ?? []
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? createdAt
    }
}
