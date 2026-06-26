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

    @Test("Production button workspace lives in the home dot-buttons directory")
    func productionWorkspaceLivesInHomeDotButtons() {
        let workspace = ButtonAutomationWorkspace.production()
        let expectedRoot = FileManager.default.homeDirectoryForCurrentUser
            .appending(path: ".buttons", directoryHint: .isDirectory)
            .appending(path: "buttons", directoryHint: .isDirectory)

        #expect(workspace.rootURL.path == expectedRoot.path)
    }
}
