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
                steps: [
                    WorkflowStep(title: "Message", kind: .showMessage, value: "Hello Buttons"),
                ]
            )
        )
        let runner = WorkflowRunner()

        let receipt = await runner.run(button: button, prompt: "Run the button.")

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
        let button = ActionButton(
            id: buttonID,
            slug: "cached-workflow",
            title: "Cached",
            subtitle: "Workflow",
            category: "Automation",
            taskDescription: "Run cached script.",
            face: ButtonFace(),
            workflow: ButtonWorkflow(
                steps: [
                    WorkflowStep(
                        title: "Workflow",
                        kind: .askAI,
                        value: "Run the cached workflow.",
                        aiConfiguration: AIConfiguration()
                    ),
                ]
            )
        )
        let buttonWorkspaceURL = try workspace.ensureWorkspace(for: button)
        let scriptURL = workspace.scriptURL(for: button)
        let script = """
        #!/bin/zsh
        echo "prompt:$BUTTON_RUN_PROMPT"
        echo "workspace:$PWD"
        echo "slug:$BUTTON_SLUG"
        echo "skills:$BUTTON_SKILLS_DIRECTORY"
        """
        try script.write(to: scriptURL, atomically: true, encoding: .utf8)

        let runner = WorkflowRunner(automationWorkspace: workspace)

        let receipt = await runner.run(button: button, prompt: "script prompt")
        let shellWorkspacePath = buttonWorkspaceURL.path.hasPrefix("/var/")
            ? "/private\(buttonWorkspaceURL.path)"
            : buttonWorkspaceURL.path

        #expect(receipt.status == .succeeded)
        #expect(receipt.output.contains("Ran cached workflow script."))
        #expect(receipt.output.contains("prompt:script prompt"))
        #expect(receipt.output.contains("workspace:\(shellWorkspacePath)"))
        #expect(receipt.output.contains("slug:cached-workflow"))
        #expect(receipt.output.contains("skills:\(workspace.skillsURL(for: button).path)"))
        #expect(FileManager.default.fileExists(atPath: workspace.logsURL(for: button).path))
    }
}
