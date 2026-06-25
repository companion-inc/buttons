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
            taskDescription: resolvedTaskDescription,
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

    // The agent gets a one-line "Goal:" from taskDescription. The user no longer
    // fills a separate goal box, so derive it from the prompt when it's blank or
    // still the seed placeholder — but only once a real prompt has been written,
    // which keeps an untouched new button matching the library's default-cleanup.
    private var resolvedTaskDescription: String {
        let trimmedDescription = taskDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPrompt = stepValue.trimmingCharacters(in: .whitespacesAndNewlines)

        let descriptionMissing = trimmedDescription.isEmpty || trimmedDescription == Self.seedTaskDescription
        let hasRealPrompt = !trimmedPrompt.isEmpty && trimmedPrompt != Self.seedPrompt

        guard descriptionMissing, hasRealPrompt else { return taskDescription }

        let firstLine = trimmedPrompt
            .split(whereSeparator: \.isNewline)
            .first
            .map(String.init) ?? trimmedPrompt
        return firstLine.trimmingCharacters(in: .whitespaces)
    }

    private static let seedPrompt = "Do this repetitive workflow end to end."
    private static let seedTaskDescription = "Do the repetitive task."

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
