import ButtonsCore
import SwiftUI

struct AppRootView: View {
    @Bindable var library: ButtonLibrary
    @State private var editorButton: ActionButton?
    @State private var pendingRun: PendingRun?
    @State private var receipt: ButtonRunReceipt?
    @State private var exportDocument = ButtonTemplateDocument(button: .empty)
    @State private var exportFilename = "Button.button.json"
    @State private var isExporting = false
    @State private var isImporting = false

    var body: some View {
        ZStack {
            AppBackgroundView()

            VStack(spacing: 0) {
                AppToolbarView(
                    newAction: newButton,
                    importAction: importButton
                )

                ButtonBoardView(
                    buttons: library.buttons,
                    runAction: run,
                    editAction: edit,
                    duplicateAction: duplicate,
                    shareAction: share,
                    deleteAction: delete
                )
                .padding(.horizontal, 28)
                .padding(.bottom, 28)
            }
        }
        .preferredColorScheme(.light)
        .environment(library)
        .task {
            await library.load()
        }
        .onReceive(NotificationCenter.default.publisher(for: .newButtonRequested)) { _ in
            newButton()
        }
        .sheet(item: $editorButton, content: ButtonEditorView.init)
        .sheet(item: $pendingRun, content: runSheet)
        .sheet(item: $receipt, content: ReceiptView.init)
        .fileExporter(
            isPresented: $isExporting,
            document: exportDocument,
            contentType: .buttonsTemplate,
            defaultFilename: exportFilename
        ) { _ in }
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.buttonsTemplate, .json]
        ) { result in
            Task {
                await handleImport(result)
            }
        }
    }

    private func runSheet(_ pendingRun: PendingRun) -> some View {
        RunButtonView(button: pendingRun.button) { values in
            Task {
                await performRun(button: pendingRun.button, values: values)
            }
        }
    }

    private func newButton() {
        editorButton = .empty
    }

    private func importButton() {
        isImporting = true
    }

    private func run(_ button: ActionButton) {
        if button.needsApproval || !button.workflow.inputs.isEmpty {
            pendingRun = PendingRun(button: button)
        } else {
            Task {
                await performRun(button: button, values: [:])
            }
        }
    }

    private func edit(_ button: ActionButton) {
        editorButton = button
    }

    private func duplicate(_ button: ActionButton) {
        var copy = button
        copy.id = UUID()
        copy.title = "\(button.title) Copy"
        Task {
            await library.add(copy)
        }
    }

    private func share(_ button: ActionButton) {
        exportDocument = ButtonTemplateDocument(button: button)
        exportFilename = "\(button.title.replacingOccurrences(of: " ", with: "-")).button.json"
        isExporting = true
    }

    private func delete(_ button: ActionButton) {
        Task {
            await library.delete(button)
        }
    }

    private func performRun(button: ActionButton, values: [String: String]) async {
        pendingRun = nil
        receipt = await library.run(button, values: values)
    }

    private func handleImport(_ result: Result<URL, Error>) async {
        do {
            let url = try result.get()
            guard url.startAccessingSecurityScopedResource() else {
                return
            }
            defer {
                url.stopAccessingSecurityScopedResource()
            }
            let data = try Data(contentsOf: url)
            try await library.importButton(from: data)
        } catch {
            library.lastError = error.localizedDescription
        }
    }
}
