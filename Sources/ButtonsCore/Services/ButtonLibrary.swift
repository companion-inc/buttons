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
    private let runner: WorkflowRunner

    public init(repository: FileButtonRepository, runner: WorkflowRunner = WorkflowRunner()) {
        self.repository = repository
        self.runner = runner
    }

    public static func production() -> ButtonLibrary {
        ButtonLibrary(repository: .production())
    }

    public func load() async {
        do {
            buttons = try await repository.load()
            isLoaded = true
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
        let button = try ButtonTemplateCodec.decode(data)
        await add(button)
    }

    @discardableResult
    public func run(_ button: ActionButton, values: [String: String]) async -> ButtonRunReceipt {
        let receipt = await runner.run(button: button, values: values)
        receipts.insert(receipt, at: 0)
        return receipt
    }

    private func save() async {
        do {
            try await repository.save(buttons)
        } catch {
            lastError = error.localizedDescription
        }
    }
}
