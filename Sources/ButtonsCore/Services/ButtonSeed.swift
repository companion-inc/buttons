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
                            executionMode: .workspaceWrite,
                            workingDirectory: AIConfiguration.defaultWorkingDirectory
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
            taskDescription: "Create an inbox triage plan for a named mailbox.",
            face: ButtonFace(symbolName: "tray.full", color: .mint, surface: .rubber),
            workflow: ButtonWorkflow(
                inputs: [
                    ButtonInputField(key: "inbox", label: "Inbox", placeholder: "Work, personal, support", defaultValue: "work"),
                ],
                steps: [
                    WorkflowStep(
                        title: "Workflow",
                        kind: .askAI,
                        value: "Clean my {{inbox}} inbox conceptually: group urgent, needs reply, waiting, receipts, and archive candidates. Return the exact queue order and next actions.",
                        aiConfiguration: AIConfiguration(
                            provider: .codex,
                            model: "",
                            systemPrompt: "Be concise and action-oriented. Do not invent messages you cannot inspect.",
                            executionMode: .workspaceWrite,
                            workingDirectory: AIConfiguration.defaultWorkingDirectory
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
                inputs: [
                    ButtonInputField(key: "repo", label: "Repo URL", placeholder: "https://github.com/org/repo", defaultValue: "https://github.com"),
                ],
                steps: [
                    WorkflowStep(
                        title: "Workflow",
                        kind: .askAI,
                        value: "Use {{repo}} as the target repository. Find the pull requests that need attention and tell me the highest-leverage next move.",
                        aiConfiguration: AIConfiguration(
                            provider: .codex,
                            model: "",
                            systemPrompt: "Prefer concrete repo evidence. State what you checked.",
                            executionMode: .workspaceWrite,
                            workingDirectory: AIConfiguration.defaultWorkingDirectory
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
                inputs: [
                    ButtonInputField(key: "topic", label: "Topic", placeholder: "What should it work on?", defaultValue: "Buttons"),
                ],
                steps: [
                    WorkflowStep(
                        title: "Workflow",
                        kind: .askAI,
                        value: "Inspect the current workspace and give the next concrete move for {{topic}}.",
                        aiConfiguration: AIConfiguration(
                            provider: .codex,
                            model: "",
                            systemPrompt: "Be direct. Return a useful result, not a conversation.",
                            executionMode: .workspaceWrite,
                            workingDirectory: AIConfiguration.defaultWorkingDirectory
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
        title: "Star Repo",
        subtitle: "GitHub",
        category: "Code",
        taskDescription: "Star a GitHub repository and open it.",
        face: ButtonFace(symbolName: "star.fill", color: .cobalt, surface: .raised),
        workflow: ButtonWorkflow(
            inputs: [
                ButtonInputField(
                    key: "repo",
                    label: "Repo",
                    placeholder: "owner/name",
                    defaultValue: "companion-inc/buttons"
                ),
            ],
            steps: [
                WorkflowStep(
                    title: "Workflow",
                    kind: .askAI,
                    value: """
                    Star the GitHub repository {{repo}} and open it in the browser.

                    The reusable script should:
                    - Read BUTTON_INPUT_REPO.
                    - Accept either owner/name or a github.com URL.
                    - Use `gh api -X PUT /user/starred/{owner}/{repo}` when GitHub CLI auth is available.
                    - Open https://github.com/{owner}/{repo}.
                    - Print whether the star succeeded or what auth/repo issue blocked it.
                    """,
                    aiConfiguration: AIConfiguration(
                        provider: .codex,
                        model: "",
                        systemPrompt: "Be operational. Produce and run the reusable script; do not stop at an explanation.",
                        executionMode: .workspaceWrite,
                        workingDirectory: AIConfiguration.defaultWorkingDirectory
                    )
                ),
            ]
        ),
        permissions: [
            ButtonPermission(title: "Local agent", detail: "Uses the installed GitHub CLI and opens the repository in the browser."),
        ]
    )
}
