import ButtonsCore
import Foundation

@MainActor
struct ButtonDraft {
    var id: UUID
    var slug: String
    var title: String
    var subtitle: String
    var category: String
    var taskDescription: String
    var symbolName: String
    var color: ButtonColor
    var surface: ButtonSurface
    var stepValue: String
    var aiProvider: AIProvider
    var aiModel: String
    var aiSystemPrompt: String
    var aiExecutionMode: AIExecutionMode
    var aiThinkingLevel: AgentThinkingLevel
    var approvalPolicy: ApprovalPolicy
    var permissionTitle: String
    var permissionDetail: String
    var createdAt: Date

    init(button: ActionButton) {
        let step = button.workflow.steps.first
        let permission = button.permissions.first
        let aiConfiguration = step?.aiConfiguration

        id = button.id
        slug = button.slug
        title = button.title
        subtitle = button.subtitle
        category = button.category
        taskDescription = button.taskDescription
        symbolName = button.face.symbolName
        color = button.face.color
        surface = button.face.surface
        stepValue = step?.value ?? ""
        aiProvider = aiConfiguration?.provider ?? .codex
        aiModel = aiConfiguration?.model ?? ""
        aiSystemPrompt = aiConfiguration?.systemPrompt ?? ""
        aiExecutionMode = aiConfiguration?.executionMode ?? .workspaceWrite
        aiThinkingLevel = aiConfiguration?.thinkingLevel ?? .high
        approvalPolicy = button.approvalPolicy
        permissionTitle = permission?.title ?? ""
        permissionDetail = permission?.detail ?? ""
        createdAt = button.createdAt
    }

    var button: ActionButton {
        let trimmedPermission = permissionTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let permissions: [ButtonPermission]
        if trimmedPermission.isEmpty {
            permissions = []
        } else {
            permissions = [ButtonPermission(title: trimmedPermission, detail: permissionDetail)]
        }

        return ActionButton(
            id: id,
            slug: slug,
            title: title,
            subtitle: subtitle,
            category: trimmedCategory,
            taskDescription: taskDescription,
            face: ButtonFace(symbolName: symbolName, color: color, surface: surface),
            workflow: ButtonWorkflow(
                steps: [
                    WorkflowStep(
                        title: "Workflow",
                        kind: .askAI,
                        value: stepValue,
                        aiConfiguration: aiConfiguration
                    ),
                ]
            ),
            approvalPolicy: approvalPolicy,
            permissions: permissions,
            createdAt: createdAt,
            updatedAt: Date()
        )
    }

    private var aiConfiguration: AIConfiguration? {
        return AIConfiguration(
            provider: aiProvider,
            model: aiModel.trimmingCharacters(in: .whitespacesAndNewlines),
            systemPrompt: aiSystemPrompt,
            executionMode: aiExecutionMode,
            thinkingLevel: aiThinkingLevel
        )
    }

    private var trimmedCategory: String {
        let value = category.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? "General" : value
    }
}
