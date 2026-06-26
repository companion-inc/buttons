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

    @Test("Button workspace tracks optimization memory")
    @MainActor
    func buttonWorkspaceTracksOptimizationMemory() async throws {
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
            taskDescription: "Run a saved workflow.",
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

        _ = try workspace.ensureWorkspace(for: button)
        let runnerURL = workspace.runnerURL(for: button)
        let runner = """
        #!/bin/zsh
        echo "optimized"
        """
        try runner.write(to: runnerURL, atomically: true, encoding: .utf8)
        workspace.markAutomationExecutable(for: button)

        #expect(workspace.automationExists(for: button))
        #expect(workspace.readAutomation(for: button).contains("optimized"))
        #expect(FileManager.default.isExecutableFile(atPath: runnerURL.path))
        #expect(FileManager.default.fileExists(atPath: workspace.logsURL(for: button).path))
        #expect(FileManager.default.fileExists(atPath: workspace.computerUseURL(for: button).path))
        #expect(FileManager.default.fileExists(atPath: workspace.computerUseToolsURL(for: button).path))

        let computerUseTools = try String(contentsOf: workspace.computerUseToolsURL(for: button), encoding: .utf8)
        #expect(computerUseTools.contains("ButtonsComputerUseRuntime"))
        #expect(computerUseTools.contains("Snapshot before acting"))
        #expect(computerUseTools.contains("Do not use shell `open`, AppleScript, `osascript`"))
        #expect(!computerUseTools.contains("open -a"))
    }
}
