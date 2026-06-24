import ButtonsCore
import Foundation

extension ActionButton {
    static var empty: ActionButton {
        ActionButton(
            title: "New Button",
            subtitle: "One click",
            taskDescription: "Do the repetitive task.",
            face: ButtonFace(symbolName: "button.programmable", color: .poppy, surface: .raised),
            workflow: ButtonWorkflow(
                steps: [
                    WorkflowStep(title: "Message", kind: .showMessage, value: "Done."),
                ]
            ),
            approvalPolicy: .automatic
        )
    }
}
