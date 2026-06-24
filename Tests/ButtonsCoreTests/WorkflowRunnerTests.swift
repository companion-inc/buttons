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
        let targetURL = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: targetURL, withIntermediateDirectories: true)
        let workspace = ButtonAutomationWorkspace(rootURL: rootURL)
        let buttonWorkspaceURL = try workspace.ensureWorkspace(for: buttonID)
        let scriptURL = workspace.scriptURL(for: buttonID)
        let script = """
        #!/bin/zsh
        echo "cached:$BUTTON_INPUT_TOPIC"
        echo "workspace:$PWD"
        echo "target:$BUTTON_TARGET_DIRECTORY"
        echo "skills:$BUTTON_SKILLS_DIRECTORY"
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
                            workingDirectory: targetURL.path
                        )
                    ),
                ]
            )
        )
        let runner = WorkflowRunner(automationWorkspace: workspace)

        let receipt = await runner.run(button: button, values: ["topic": "script"])
        let shellWorkspacePath = buttonWorkspaceURL.path.hasPrefix("/var/")
            ? "/private\(buttonWorkspaceURL.path)"
            : buttonWorkspaceURL.path

        #expect(receipt.status == .succeeded)
        #expect(receipt.output.contains("Ran cached workflow script."))
        #expect(receipt.output.contains("cached:script"))
        #expect(receipt.output.contains("workspace:\(shellWorkspacePath)"))
        #expect(receipt.output.contains("target:\(targetURL.path)"))
        #expect(receipt.output.contains("skills:\(workspace.skillsURL(for: buttonID).path)"))
        #expect(FileManager.default.fileExists(atPath: workspace.logsURL(for: buttonID).path))
    }
}
