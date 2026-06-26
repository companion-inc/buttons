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
        face: ButtonFace(symbolName: "star.fill", color: .cobalt, surface: .raised),
        workflow: ButtonWorkflow(
            steps: [
                WorkflowStep(
                    title: "Workflow",
                    kind: .askAI,
                    value: """
                    Star the GitHub repository named in this run prompt and open it in the browser.

                    Accept either owner/name or a github.com URL. Use `gh api -X PUT /user/starred/{owner}/{repo}` when GitHub CLI auth is available, then open https://github.com/{owner}/{repo}. When no repository is named, ask for the repository instead of guessing. Print what happened and what blocked the star when auth or repo access fails.
                    """,
                    aiConfiguration: AIConfiguration(
                        provider: .codex,
                        model: "",
                        systemPrompt: "Be operational. Run the button now, then improve its durable memory; do not stop at an explanation.",
                        executionMode: .workspaceWrite
                    )
                ),
            ]
        ),
        permissions: [
            ButtonPermission(title: "Local agent", detail: "Uses the installed GitHub CLI and opens the repository in the browser."),
        ]
    )
}
