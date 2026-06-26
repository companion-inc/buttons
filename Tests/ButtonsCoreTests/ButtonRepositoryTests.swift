import ButtonsCore
import Foundation
import Testing

@Suite("Button repository")
struct ButtonRepositoryTests {
    @Test("Repository saves and loads buttons")
    func savesAndLoadsButtons() async throws {
        let url = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
            .appending(path: "buttons.json")
        let repository = FileButtonRepository(fileURL: url)
        let button = ButtonSeed.defaults[0]

        try await repository.save([button])
        let loaded = try await repository.load()

        #expect(loaded.count == 1)
        #expect(loaded.first?.id == button.id)
        #expect(loaded.first?.title == button.title)
        #expect(loaded.first?.workflow == button.workflow)
    }

    @Test("Missing repository file returns seed buttons")
    func missingFileReturnsSeedButtons() async throws {
        let url = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
            .appending(path: "buttons.json")
        let repository = FileButtonRepository(fileURL: url)

        let loaded = try await repository.load()

        #expect(loaded == ButtonSeed.defaults)
        #expect(loaded.count == 1)
    }

    @Test("Only seed button stars the internal repository")
    func onlySeedButtonStarsInternalRepository() {
        let button = ButtonSeed.defaults[0]

        #expect(ButtonSeed.defaults.count == 1)
        #expect(button.title == "Star Repo")
        #expect(button.slug == "star-repo")
        #expect(button.face.color == .lemon)
        #expect(button.approvalPolicy == .never)
        #expect(button.requiresRunConfirmation == false)
        #expect(button.workflow.steps.first?.kind == .askAI)
        #expect(button.workflow.steps.first?.aiConfiguration?.provider == .codex)
        #expect(button.workflow.steps.first?.aiConfiguration?.executionMode == .dangerouslyRun)
        #expect(button.workflow.steps.first?.aiConfiguration?.thinkingLevel == .low)
        #expect(button.workflow.steps.first?.value.contains("https://github.com/companion-inc/buttons") == true)
        #expect(button.workflow.steps.first?.value.contains("gh api") == false)
        #expect(button.workflow.steps.first?.value.contains("gh repo view") == false)
    }

    @Test("Library collapses duplicate starter buttons")
    func libraryCollapsesDuplicateStarterButtons() async throws {
        let rootURL = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
        let buttonURL = rootURL.appending(path: "buttons.json")
        let runsURL = rootURL.appending(path: "runs.json")
        let repository = FileButtonRepository(fileURL: buttonURL)
        let receiptRepository = ButtonRunReceiptRepository(fileURL: runsURL)
        let customButton = ActionButton(
            title: "Custom",
            subtitle: "Saved prompt",
            category: "Personal",
            taskDescription: "Do a custom task.",
            face: ButtonFace(symbolName: "bolt.fill", color: .poppy, surface: .raised),
            workflow: ButtonWorkflow(
                steps: [
                    WorkflowStep(
                        title: "Workflow",
                        kind: .askAI,
                        value: "Do the custom task.",
                        aiConfiguration: AIConfiguration()
                    ),
                ]
            )
        )

        try await repository.save([
            ButtonSeed.starRepo,
            customButton,
            ButtonSeed.starRepo,
        ])

        let library = await ButtonLibrary(
            repository: repository,
            receiptRepository: receiptRepository
        )
        await library.load()

        let starButtons = await library.buttons.filter { $0.id == ButtonSeed.starRepo.id || $0.title == ButtonSeed.starRepo.title }
        let loadedCustomButton = await library.buttons.first { $0.id == customButton.id }

        #expect(starButtons.count == 1)
        #expect(loadedCustomButton?.title == "Custom")
    }

    @Test("Production button workspace lives in the home dot-buttons directory")
    func productionWorkspaceLivesInHomeDotButtons() {
        let workspace = ButtonAutomationWorkspace.production()
        let expectedRoot = FileManager.default.homeDirectoryForCurrentUser
            .appending(path: ".buttons", directoryHint: .isDirectory)
            .appending(path: "buttons", directoryHint: .isDirectory)

        #expect(workspace.rootURL.path == expectedRoot.path)
    }
}
