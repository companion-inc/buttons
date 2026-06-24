import ButtonsCore
import Foundation

@MainActor
struct ButtonDraft {
    var id: UUID
    var title: String
    var subtitle: String
    var taskDescription: String
    var symbolName: String
    var color: ButtonColor
    var surface: ButtonSurface
    var stepKind: WorkflowStepKind
    var stepValue: String
    var approvalPolicy: ApprovalPolicy
    var inputKey: String
    var inputLabel: String
    var inputDefault: String
    var permissionTitle: String
    var permissionDetail: String
    var createdAt: Date

    init(button: ActionButton) {
        let input = button.workflow.inputs.first
        let step = button.workflow.steps.first
        let permission = button.permissions.first

        id = button.id
        title = button.title
        subtitle = button.subtitle
        taskDescription = button.taskDescription
        symbolName = button.face.symbolName
        color = button.face.color
        surface = button.face.surface
        stepKind = step?.kind ?? .showMessage
        stepValue = step?.value ?? ""
        approvalPolicy = button.approvalPolicy
        inputKey = input?.key ?? ""
        inputLabel = input?.label ?? ""
        inputDefault = input?.defaultValue ?? ""
        permissionTitle = permission?.title ?? ""
        permissionDetail = permission?.detail ?? ""
        createdAt = button.createdAt
    }

    var button: ActionButton {
        let trimmedInputKey = inputKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let inputs: [ButtonInputField]
        if trimmedInputKey.isEmpty {
            inputs = []
        } else {
            inputs = [
                ButtonInputField(
                    key: trimmedInputKey,
                    label: inputLabel.isEmpty ? trimmedInputKey : inputLabel,
                    defaultValue: inputDefault
                ),
            ]
        }

        let trimmedPermission = permissionTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let permissions: [ButtonPermission]
        if trimmedPermission.isEmpty {
            permissions = []
        } else {
            permissions = [ButtonPermission(title: trimmedPermission, detail: permissionDetail)]
        }

        return ActionButton(
            id: id,
            title: title,
            subtitle: subtitle,
            taskDescription: taskDescription,
            face: ButtonFace(symbolName: symbolName, color: color, surface: surface),
            workflow: ButtonWorkflow(
                inputs: inputs,
                steps: [
                    WorkflowStep(title: stepKind.title, kind: stepKind, value: stepValue),
                ]
            ),
            approvalPolicy: approvalPolicy,
            permissions: permissions,
            createdAt: createdAt,
            updatedAt: Date()
        )
    }
}
