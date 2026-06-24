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

    @Test("Button workflow runs cached workflow script when present")
    @MainActor
    func promptButtonRunsCachedWorkflowScriptWhenPresent() async throws {
        let buttonID = UUID()
        let rootURL = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
        let workspace = ButtonAutomationWorkspace(rootURL: rootURL)
        let buttonWorkspaceURL = try workspace.ensureWorkspace(for: buttonID)
        let scriptURL = workspace.scriptURL(for: buttonID)
        let script = """
        #!/bin/zsh
        echo "cached:$BUTTON_INPUT_TOPIC"
        """
        try script.write(to: scriptURL, atomically: true, encoding: .utf8)

        let button = ActionButton(
            id: buttonID,
            title: "Cached",
            subtitle: "Workflow",
            category: "Automation",
            taskDescription: "Run cached script.",
            face: ButtonFace(),
            workflow: ButtonWorkflow(
                inputs: [
                    ButtonInputField(key: "topic", label: "Topic", defaultValue: "Buttons"),
                ],
                steps: [
                    WorkflowStep(
                        title: "Workflow",
                        kind: .askAI,
                        value: "Run {{topic}}",
                        aiConfiguration: AIConfiguration(
                            workingDirectory: buttonWorkspaceURL.path
                        )
                    ),
                ]
            )
        )
        let runner = WorkflowRunner(automationWorkspace: workspace)

        let receipt = await runner.run(button: button, values: ["topic": "script"])

        #expect(receipt.status == .succeeded)
        #expect(receipt.output.contains("Ran cached workflow script."))
        #expect(receipt.output.contains("cached:script"))
    }
}
