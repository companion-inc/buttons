import Foundation

public enum ButtonSeed {
    public static let defaults: [ActionButton] = [
        starRepo,
        ActionButton(
            title: "Plan Day",
            subtitle: "Daily plan",
            category: "Planning",
            taskDescription: "Turn today's work into a tight plan.",
            face: ButtonFace(symbolName: "calendar.badge.clock", color: .lemon, surface: .raised),
            workflow: ButtonWorkflow(
                steps: [
                    WorkflowStep(
                        title: "Workflow",
                        kind: .askAI,
                        value: "Look at the current day context available from this machine and turn today into a tight plan with prep blocks, follow-ups, and the first next action.",
                        aiConfiguration: AIConfiguration(
                            provider: .codex,
                            model: "",
                            systemPrompt: "Be direct and operational. Return the plan, not a chatty explanation.",
                            executionMode: .workspaceWrite
                        )
                    ),
                ]
            ),
            permissions: [
                ButtonPermission(title: "Local agent", detail: "Runs the installed Codex or Claude Code CLI using its local login."),
            ]
        ),
        ActionButton(
            title: "Clean Inbox",
            subtitle: "Triage",
            category: "Inbox",
            taskDescription: "Create an inbox triage plan.",
            face: ButtonFace(symbolName: "tray.full", color: .mint, surface: .rubber),
            workflow: ButtonWorkflow(
                steps: [
                    WorkflowStep(
                        title: "Workflow",
                        kind: .askAI,
                        value: "Clean my work inbox conceptually: group urgent, needs reply, waiting, receipts, and archive candidates. Return the exact queue order and next actions. Use the mailbox named in this run prompt when I add one.",
                        aiConfiguration: AIConfiguration(
                            provider: .codex,
                            model: "",
                            systemPrompt: "Be concise and action-oriented. Do not invent messages you cannot inspect.",
                            executionMode: .workspaceWrite
                        )
                    ),
                ]
            ),
            permissions: [
                ButtonPermission(title: "Local agent", detail: "Runs the installed Codex or Claude Code CLI using its local login."),
            ]
        ),
        ActionButton(
            title: "Open PR",
            subtitle: "Review queue",
            category: "Code",
            taskDescription: "Handle pull request context for a repository.",
            face: ButtonFace(symbolName: "point.topleft.down.curvedto.point.bottomright.up", color: .cobalt, surface: .metal),
            workflow: ButtonWorkflow(
                steps: [
                    WorkflowStep(
                        title: "Workflow",
                        kind: .askAI,
                        value: "Find pull requests that need attention for the repository named in this run prompt. When no repository is named, use companion-inc/buttons. Return the highest-leverage next move and cite what you checked.",
                        aiConfiguration: AIConfiguration(
                            provider: .codex,
                            model: "",
                            systemPrompt: "Prefer concrete repo evidence. State what you checked.",
                            executionMode: .workspaceWrite
                        )
                    ),
                ]
            ),
            permissions: [
                ButtonPermission(title: "Local agent", detail: "Runs the installed Codex or Claude Code CLI using its local login."),
            ]
        ),
        ActionButton(
            title: "Run Agent",
            subtitle: "Workspace task",
            category: "Automation",
            taskDescription: "Send a reusable task to the local Codex or Claude Code CLI.",
            face: ButtonFace(symbolName: "terminal.fill", color: .rose, surface: .raised),
            workflow: ButtonWorkflow(
                steps: [
                    WorkflowStep(
                        title: "Workflow",
                        kind: .askAI,
                        value: "Inspect the current button workspace, complete the repetitive task described in this run prompt, and improve the button's memory so the next click is cheaper.",
                        aiConfiguration: AIConfiguration(
                            provider: .codex,
                            model: "",
                            systemPrompt: "Run the button as an operational task. Improve its durable memory after the task is done.",
                            executionMode: .workspaceWrite
                        )
                    ),
                ]
            ),
            permissions: [
                ButtonPermission(title: "Local agent", detail: "Runs the installed Codex or Claude Code CLI using its local login."),
            ]
        ),
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
                    Star the GitHub repository companion-inc/buttons and open it in the browser.

                    Improve this button so later runs can handle a different repository when the run prompt names one. Accept either owner/name or a github.com URL from the run prompt. Use `gh api -X PUT /user/starred/{owner}/{repo}` when GitHub CLI auth is available, then open https://github.com/{owner}/{repo}. Print what happened and what blocked the star when auth or repo access fails.
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
