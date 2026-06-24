@testable import ButtonsCore
import Foundation
import Testing

@Suite("Local agent task configuration")
struct LocalAgentTaskTests {
    @Test("Dangerous local agent mode requires approval")
    func dangerousAgentModeRequiresApproval() {
        let button = ActionButton(
            title: "Ship",
            subtitle: "Agent task",
            taskDescription: "Run a local agent",
            face: ButtonFace(symbolName: "paperplane.fill", color: .poppy, surface: .raised),
            workflow: ButtonWorkflow(
                steps: [
                    WorkflowStep(
                        title: "Agent task",
                        kind: .askAI,
                        value: "Fix the bug",
                        aiConfiguration: AIConfiguration(executionMode: .dangerouslyRun)
                    ),
                ]
            )
        )

        #expect(button.needsApproval)
        #expect(button.requiresRunConfirmation)
    }

    @Test("Run immediately skips confirmation even for dangerous mode")
    func runImmediatelySkipsConfirmation() {
        let button = ActionButton(
            title: "Ship",
            subtitle: "Agent task",
            taskDescription: "Run a local agent",
            face: ButtonFace(symbolName: "paperplane.fill", color: .poppy, surface: .raised),
            workflow: ButtonWorkflow(
                steps: [
                    WorkflowStep(
                        title: "Agent task",
                        kind: .askAI,
                        value: "Fix the bug",
                        aiConfiguration: AIConfiguration(executionMode: .dangerouslyRun)
                    ),
                ]
            ),
            approvalPolicy: .never
        )

        #expect(!button.needsApproval)
        #expect(!button.requiresRunConfirmation)
    }

    @Test("Codex dangerous mode uses Codex CLI dangerous flag")
    func codexDangerousModeUsesCodexDangerousFlag() {
        let configuration = AIConfiguration(
            provider: .codex,
            model: "",
            executionMode: .dangerouslyRun,
            workingDirectory: "/tmp/project"
        )

        let arguments = LocalAgentRunner.codexArguments(
            configuration: configuration,
            prompt: "Run the workflow",
            lastMessagePath: "/tmp/last.txt"
        )

        #expect(arguments.contains("exec"))
        #expect(arguments.contains("--dangerously-bypass-approvals-and-sandbox"))
        #expect(arguments.contains("danger-full-access"))
        #expect(arguments.contains("/tmp/project"))
    }

    @Test("Claude dangerous mode uses Claude Code dangerous flag")
    func claudeDangerousModeUsesClaudeDangerousFlag() {
        let configuration = AIConfiguration(
            provider: .claudeCode,
            model: "",
            executionMode: .dangerouslyRun,
            workingDirectory: "/tmp/project"
        )

        let arguments = LocalAgentRunner.claudeArguments(
            configuration: configuration,
            prompt: "Run the workflow"
        )

        #expect(arguments.contains("-p"))
        #expect(arguments.contains("--dangerously-skip-permissions"))
        #expect(arguments.contains("bypassPermissions"))
        #expect(arguments.contains("/tmp/project"))
    }

    @Test("Temporary API provider names decode to local CLI providers")
    func legacyProviderNamesDecodeToLocalCLIProviders() throws {
        let codex = try JSONDecoder().decode(AIProvider.self, from: #""openAI""#.data(using: .utf8)!)
        let claude = try JSONDecoder().decode(AIProvider.self, from: #""anthropic""#.data(using: .utf8)!)

        #expect(codex == .codex)
        #expect(claude == .claudeCode)
    }
}
