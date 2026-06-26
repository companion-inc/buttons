import ButtonsCore
import Foundation

extension ActionButton {
    static var empty: ActionButton {
        ActionButton(
            title: "New Button",
            subtitle: "Draft",
            category: "General",
            taskDescription: "",
            face: ButtonFace(symbolName: "button.programmable", color: .poppy, surface: .raised),
            workflow: ButtonWorkflow(
                steps: [
                    WorkflowStep(
                        title: "Workflow",
                        kind: .askAI,
                        value: "",
                        aiConfiguration: AIConfiguration()
                    ),
                ]
            ),
            approvalPolicy: .automatic
        )
    }
}
