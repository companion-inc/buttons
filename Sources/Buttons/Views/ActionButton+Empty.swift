import ButtonsCore
import Foundation

extension ActionButton {
    static var empty: ActionButton {
        ActionButton(
            title: "New Button",
            subtitle: "Workflow",
            category: "General",
            taskDescription: "Do the repetitive task.",
            face: ButtonFace(symbolName: "button.programmable", color: .poppy, surface: .raised),
            workflow: ButtonWorkflow(
                steps: [
                    WorkflowStep(
                        title: "Workflow",
                        kind: .askAI,
                        value: "Do this repetitive workflow end to end.",
                        aiConfiguration: AIConfiguration()
                    ),
                ]
            ),
            approvalPolicy: .automatic
        )
    }
}
