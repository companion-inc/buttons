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
                    kind: .runShellCommand,
                    value: """
                    set -euo pipefail

                    gh api -X PUT /user/starred/companion-inc/buttons
                    gh repo view companion-inc/buttons --web
                    printf 'Starred companion-inc/buttons and opened https://github.com/companion-inc/buttons.\\n'
                    """
                ),
            ]
        ),
        approvalPolicy: .never,
        permissions: [
            ButtonPermission(title: "Local agent", detail: "Uses the installed GitHub CLI and opens the repository in the browser."),
        ]
    )
}
