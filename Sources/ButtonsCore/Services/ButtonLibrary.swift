import Foundation
import Observation

@MainActor
@Observable
public final class ButtonLibrary {
    public private(set) var buttons: [ActionButton] = []
    public private(set) var receipts: [ButtonRunReceipt] = []
    public private(set) var isLoaded = false
    public var lastError: String?

    private let repository: FileButtonRepository
    private let receiptRepository: ButtonRunReceiptRepository
    private let runner: WorkflowRunner

    public init(
        repository: FileButtonRepository,
        receiptRepository: ButtonRunReceiptRepository = .production(),
        runner: WorkflowRunner = WorkflowRunner()
    ) {
        self.repository = repository
        self.receiptRepository = receiptRepository
        self.runner = runner
    }

    public static func production() -> ButtonLibrary {
        ButtonLibrary(
            repository: .production(),
            receiptRepository: .production(),
            runner: WorkflowRunner()
        )
    }

    public func load() async {
        do {
            let loadedButtons = try await repository.load()
            buttons = Self.withRequiredDefaults(loadedButtons.map(Self.migratedButton))
            receipts = try await receiptRepository.load()
            isLoaded = true
            if buttons != loadedButtons {
                await save()
            }
        } catch {
            buttons = ButtonSeed.defaults
            isLoaded = true
            lastError = error.localizedDescription
        }
    }

    public func add(_ button: ActionButton) async {
        buttons.insert(button.updated(), at: 0)
        await save()
    }

    public func update(_ button: ActionButton) async {
        guard let index = buttons.firstIndex(where: { $0.id == button.id }) else {
            return
        }
        buttons[index] = button.updated()
        await save()
    }

    public func delete(_ button: ActionButton) async {
        buttons.removeAll { $0.id == button.id }
        await save()
    }

    public func button(id: UUID) -> ActionButton? {
        buttons.first { $0.id == id }
    }

    public func importButton(from data: Data) async throws {
        let button = Self.migratedButton(try ButtonTemplateCodec.decode(data))
        await add(button)
    }

    @discardableResult
    public func run(
        _ button: ActionButton,
        values: [String: String],
        configurationOverride: AIConfiguration? = nil
    ) async -> ButtonRunReceipt {
        let receipt = await runner.run(
            button: button,
            values: values,
            configurationOverride: configurationOverride
        )
        receipts.insert(receipt, at: 0)
        await saveReceipts()
        return receipt
    }

    public func receipts(for button: ActionButton) -> [ButtonRunReceipt] {
        receipts.filter { $0.buttonID == button.id }
    }

    private func save() async {
        do {
            try await repository.save(buttons)
        } catch {
            lastError = error.localizedDescription
        }
    }

    private func saveReceipts() async {
        do {
            try await receiptRepository.save(Array(receipts.prefix(500)))
        } catch {
            lastError = error.localizedDescription
        }
    }

    private static func migratedButton(_ button: ActionButton) -> ActionButton {
        var copy = button
        let originalSteps = copy.workflow.steps

        if copy.title == "New Button", copy.taskDescription == "Do the repetitive task.", copy.workflow.steps.first?.value == "Do this repetitive workflow end to end." {
            return ButtonSeed.starRepo
        }

        if copy.title == "Star Repo" {
            copy = ButtonSeed.starRepo
        }

        if copy.title == "Ask AI", copy.subtitle == "ChatGPT or Claude" {
            copy.title = "Run Agent"
            copy.subtitle = "Workspace task"
            copy.category = "Automation"
            copy.taskDescription = "Send a reusable task to the local Codex or Claude Code CLI."
            copy.face = ButtonFace(symbolName: "terminal.fill", color: .rose, surface: .raised)
        }

        if copy.title == "Run Agent", copy.subtitle == "Codex task" {
            copy.subtitle = "Workspace task"
            copy.category = "Automation"
        }

        if copy.subtitle == "Calendar setup" || copy.subtitle == "Triage prompt" || copy.subtitle == "GitHub" || copy.subtitle == "Prompt preset" {
            copy.subtitle = migratedSubtitle(for: copy)
        }

        if copy.category == "General" {
            copy.category = migratedCategory(for: copy)
        }

        copy.permissions = copy.permissions.map { permission in
            guard permission.title == "AI provider" else {
                return ButtonPermission(
                    id: permission.id,
                    title: "Local agent",
                    detail: "Runs the installed Codex or Claude Code CLI using its local login."
                )
            }

            return ButtonPermission(
                id: permission.id,
                title: "Local agent",
                detail: "Runs the installed Codex or Claude Code CLI using its local login."
            )
        }

        if copy.permissions.isEmpty {
            copy.permissions = [
                ButtonPermission(
                    title: "Local agent",
                    detail: "Runs the installed Codex or Claude Code CLI using its local login."
                ),
            ]
        }

        copy.workflow.steps = [
            WorkflowStep(
                title: "Workflow",
                kind: .askAI,
                value: promptValue(button: copy, originalSteps: originalSteps),
                aiConfiguration: migratedConfiguration(from: originalSteps.first?.aiConfiguration)
            ),
        ]

        return copy
    }

    private static func withRequiredDefaults(_ buttons: [ActionButton]) -> [ActionButton] {
        var copy = buttons

        if let starIndex = copy.firstIndex(where: { $0.id == ButtonSeed.starRepo.id || $0.title == ButtonSeed.starRepo.title }) {
            var starButton = copy.remove(at: starIndex)
            starButton = ButtonSeed.starRepo
            copy.insert(starButton, at: 0)
        } else {
            copy.insert(ButtonSeed.starRepo, at: 0)
        }

        return copy
    }

    private static func migratedConfiguration(from configuration: AIConfiguration?) -> AIConfiguration {
        guard var configuration else {
            return AIConfiguration(
                provider: .codex,
                model: "",
                systemPrompt: "Be direct. Complete the button's workflow as an operational task.",
                executionMode: .workspaceWrite,
                workingDirectory: AIConfiguration.defaultWorkingDirectory
            )
        }

        configuration.model = configuration.model.trimmingCharacters(in: .whitespacesAndNewlines)
        configuration.workingDirectory = configuration.workingDirectory.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? AIConfiguration.defaultWorkingDirectory
            : configuration.workingDirectory

        return configuration
    }

    private static func promptValue(button: ActionButton, originalSteps: [WorkflowStep]) -> String {
        if originalSteps.count == 1, let onlyStep = originalSteps.first, onlyStep.kind == .askAI {
            return onlyStep.value
        }

        let stepSummary = originalSteps
            .map(promptInstruction)
            .joined(separator: "\n")

        if stepSummary.isEmpty {
            return button.taskDescription
        }

        return """
        Complete this saved button as a workflow.

        Button: \(button.title)
        Goal: \(button.taskDescription)

        Prior recipe intent:
        \(stepSummary)
        """
    }

    private static func promptInstruction(_ step: WorkflowStep) -> String {
        switch step.kind {
        case .openURL:
            "- Open or use this URL: \(step.value)"
        case .copyText:
            "- Use this text: \(step.value)"
        case .runShortcut:
            "- Run or account for this Shortcut: \(step.value)"
        case .runShellCommand:
            "- Run or reason about this command: \(step.value)"
        case .showMessage:
            "- Produce this message or result: \(step.value)"
        case .askAI:
            "- \(step.value)"
        }
    }

    private static func migratedCategory(for button: ActionButton) -> String {
        switch button.title {
        case "Plan Day":
            "Planning"
        case "Clean Inbox":
            "Inbox"
        case "Open PR":
            "Code"
        case "Run Agent":
            "Automation"
        default:
            button.category
        }
    }

    private static func migratedSubtitle(for button: ActionButton) -> String {
        switch button.title {
        case "Plan Day":
            "Daily plan"
        case "Clean Inbox":
            "Triage"
        case "Open PR":
            "Review queue"
        default:
            button.subtitle
        }
    }
}
