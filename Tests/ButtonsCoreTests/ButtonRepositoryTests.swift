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

        #expect(!loaded.isEmpty)
    }
}
