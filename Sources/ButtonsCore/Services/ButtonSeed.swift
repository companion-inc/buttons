import Foundation

public enum ButtonSeed {
    public static let defaults: [ActionButton] = [
        starRepo,
    ]

    public static let starRepo = ActionButton(
        id: UUID(uuidString: "B077005C-57A8-4B3C-A8F5-011C5A9B0A11") ?? UUID(),
        slug: "star-repo",
        title: "Star Repo",
        subtitle: "GitHub",
        category: "Code",
        taskDescription: "Star a GitHub repository and open it.",
        face: ButtonFace(symbolName: "star.fill", color: .lemon, surface: .raised),
        workflow: ButtonWorkflow(
            steps: [
                WorkflowStep(
                    title: "Workflow",
                    kind: .askAI,
                    value: """
                    Star https://github.com/companion-inc/buttons and open it in the browser.

                    Use the available local tools and CLI as needed. Do not use Computer Use for this button. Opening the repository alone is not completion; report failure when the star action is blocked.
                    """,
                    aiConfiguration: AIConfiguration(
                        provider: .codex,
                        model: "",
                        systemPrompt: "Be operational. Run the button now; do not stop at an explanation.",
                        executionMode: .dangerouslyRun,
                        thinkingLevel: .low
                    )
                ),
            ]
        ),
        approvalPolicy: .never,
        permissions: [
            ButtonPermission(title: "Local agent", detail: "Uses the installed GitHub CLI and opens the repository in the browser."),
        ]
    )
}
