import Foundation

public enum ButtonSeed {
    public static let defaults: [ActionButton] = [
        ActionButton(
            title: "Plan Day",
            subtitle: "Calendar setup",
            taskDescription: "Open the calendar and copy a planning prompt.",
            face: ButtonFace(symbolName: "calendar.badge.clock", color: .lemon, surface: .raised),
            workflow: ButtonWorkflow(
                steps: [
                    WorkflowStep(title: "Open Calendar", kind: .openURL, value: "x-apple-calevent://"),
                    WorkflowStep(title: "Copy prompt", kind: .copyText, value: "Turn today's meetings into a tight plan with prep blocks and follow-ups."),
                ]
            ),
            permissions: [
                ButtonPermission(title: "Calendar", detail: "Opens the local Calendar app."),
                ButtonPermission(title: "Clipboard", detail: "Copies the planning prompt."),
            ]
        ),
        ActionButton(
            title: "Clean Inbox",
            subtitle: "Triage prompt",
            taskDescription: "Copy an inbox triage prompt for the selected mail pile.",
            face: ButtonFace(symbolName: "tray.full", color: .mint, surface: .rubber),
            workflow: ButtonWorkflow(
                inputs: [
                    ButtonInputField(key: "inbox", label: "Inbox", placeholder: "Work, personal, support", defaultValue: "work"),
                ],
                steps: [
                    WorkflowStep(title: "Copy triage prompt", kind: .copyText, value: "Clean my {{inbox}} inbox: group urgent, needs reply, waiting, receipts, and archive candidates."),
                ]
            ),
            permissions: [
                ButtonPermission(title: "Clipboard", detail: "Copies a configured prompt."),
            ]
        ),
        ActionButton(
            title: "Open PR",
            subtitle: "GitHub",
            taskDescription: "Open GitHub pull requests.",
            face: ButtonFace(symbolName: "point.topleft.down.curvedto.point.bottomright.up", color: .cobalt, surface: .metal),
            workflow: ButtonWorkflow(
                inputs: [
                    ButtonInputField(key: "repo", label: "Repo URL", placeholder: "https://github.com/org/repo", defaultValue: "https://github.com"),
                ],
                steps: [
                    WorkflowStep(title: "Open pull requests", kind: .openURL, value: "{{repo}}/pulls"),
                ]
            ),
            permissions: [
                ButtonPermission(title: "Browser", detail: "Opens the pull request page."),
            ]
        ),
    ]
}
