import ButtonsCore
import Foundation
import Testing

@Suite("Workflow runner")
struct WorkflowRunnerTests {
    @Test("Show message button returns a receipt")
    @MainActor
    func showMessageButtonReturnsReceipt() async {
        let button = ActionButton(
            title: "Say It",
            subtitle: "Message",
            taskDescription: "Show a rendered message.",
            face: ButtonFace(),
            workflow: ButtonWorkflow(
                inputs: [
                    ButtonInputField(key: "name", label: "Name", defaultValue: "Advait"),
                ],
                steps: [
                    WorkflowStep(title: "Message", kind: .showMessage, value: "Hello {{name}}"),
                ]
            )
        )
        let runner = WorkflowRunner()

        let receipt = await runner.run(button: button, values: ["name": "Buttons"])

        #expect(receipt.status == .succeeded)
        #expect(receipt.output == "Hello Buttons")
    }
}
