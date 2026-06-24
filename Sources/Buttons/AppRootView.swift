import ButtonsCore
import SwiftUI

struct AppRootView: View {
    @Bindable var library: ButtonLibrary
    @State private var detailSelection: DetailSelection?
    @State private var exportDocument = ButtonTemplateDocument(button: .empty)
    @State private var exportFilename = "Button.button.json"
    @State private var isExporting = false
    @State private var isImporting = false
    @State private var pendingRunButton: ActionButton?
    @State private var skipFutureConfirmations = false
    @Namespace private var buttonZoomNamespace

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
                    selectedButtonID: activeZoomButtonID,
                    namespace: buttonZoomNamespace,
                    runAction: requestRun,
                    editAction: openButton,
                    duplicateAction: duplicate,
                    shareAction: share,
                    runsAction: openButton,
                    deleteAction: delete
                )
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 28)
                .padding(.bottom, 28)
            }
            .scaleEffect(isOverlayActive ? 0.985 : 1)
            .opacity(isOverlayActive ? 0 : 1)
            .allowsHitTesting(!isOverlayActive)

            if let selectedButton {
                ButtonDetailScreenView(
                    button: selectedButton,
                    namespace: buttonZoomNamespace,
                    closeAction: closeDetail,
                    duplicateAction: duplicate,
                    shareAction: share,
                    deleteAction: delete
                )
                .zIndex(10)
                .transition(.opacity)
            }

            if let pendingRunButton {
                RunConfirmationView(
                    button: pendingRunButton,
                    namespace: buttonZoomNamespace,
                    doNotAskAgain: $skipFutureConfirmations,
                    cancelAction: cancelPendingRun,
                    runAction: confirmPendingRun
                )
                .zIndex(20)
                .transition(.scale(scale: 0.96).combined(with: .opacity))
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

    private var selectedButton: ActionButton? {
        guard let id = detailSelection?.buttonID else {
            return nil
        }

        return library.button(id: id)
    }

    private var isOverlayActive: Bool {
        detailSelection != nil || pendingRunButton != nil
    }

    private var activeZoomButtonID: UUID? {
        detailSelection?.buttonID ?? pendingRunButton?.id
    }

    private func newButton() {
        let button = ActionButton.empty
        Task {
            await library.add(button)
            withAnimation(.spring(response: 0.42, dampingFraction: 0.84)) {
                detailSelection = .button(button.id)
            }
        }
    }

    private func importButton() {
        isImporting = true
    }

    private func openButton(_ button: ActionButton) {
        withAnimation(.spring(response: 0.42, dampingFraction: 0.84)) {
            pendingRunButton = nil
            skipFutureConfirmations = false
            if detailSelection?.buttonID == button.id {
                detailSelection = nil
            } else {
                detailSelection = .button(button.id)
            }
        }
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

    private func showRuns(_ button: ActionButton) {
        withAnimation(.spring(response: 0.42, dampingFraction: 0.84)) {
            detailSelection = .button(button.id)
        }
    }

    private func requestRun(_ button: ActionButton) {
        guard button.requiresRunConfirmation else {
            run(button)
            return
        }

        withAnimation(.spring(response: 0.42, dampingFraction: 0.84)) {
            detailSelection = nil
            pendingRunButton = button
            skipFutureConfirmations = false
        }
    }

    private func confirmPendingRun(values: [String: String]) {
        guard var button = pendingRunButton else {
            return
        }

        let shouldSkipFutureConfirmations = skipFutureConfirmations
        withAnimation(.spring(response: 0.36, dampingFraction: 0.88)) {
            pendingRunButton = nil
            skipFutureConfirmations = false
        }

        Task {
            if shouldSkipFutureConfirmations {
                button.approvalPolicy = .never
                await library.update(button)
            }

            await runNow(button, values: values)
        }
    }

    private func cancelPendingRun() {
        withAnimation(.spring(response: 0.36, dampingFraction: 0.88)) {
            pendingRunButton = nil
            skipFutureConfirmations = false
        }
    }

    private func run(_ button: ActionButton) {
        Task {
            await runNow(button, values: defaultValues(for: button))
        }
    }

    private func runNow(_ button: ActionButton, values: [String: String]) async {
        let currentButton = library.button(id: button.id) ?? button
        _ = await library.run(
            currentButton,
            values: values,
            configurationOverride: currentButton.workflow.steps.first?.aiConfiguration
        )
    }

    private func defaultValues(for button: ActionButton) -> [String: String] {
        Dictionary(uniqueKeysWithValues: button.workflow.inputs.map { ($0.key, $0.defaultValue) })
    }

    private func delete(_ button: ActionButton) {
        Task {
            await library.delete(button)
            if detailSelection?.buttonID == button.id {
                withAnimation(.spring(response: 0.36, dampingFraction: 0.88)) {
                    detailSelection = nil
                }
            }
            if pendingRunButton?.id == button.id {
                pendingRunButton = nil
                skipFutureConfirmations = false
            }
        }
    }

    private func closeDetail() {
        withAnimation(.spring(response: 0.36, dampingFraction: 0.88)) {
            detailSelection = nil
        }
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
