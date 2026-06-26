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
    @State private var pendingRunReceipt: ButtonRunReceipt?
    @State private var pendingRunEvents: [String] = []
    @State private var isPendingRunRunning = false
    @State private var pendingRunTask: Task<Void, Never>?
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
                    isRunning: isPendingRunRunning,
                    receipt: pendingRunReceipt,
                    runEvents: pendingRunEvents,
                    cancelAction: cancelPendingRun,
                    saveAction: savePendingRunPrompt,
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
            pendingRunReceipt = nil
            pendingRunEvents = []
            isPendingRunRunning = false
            pendingRunTask?.cancel()
            pendingRunTask = nil
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
        guard !isPendingRunRunning else {
            return
        }

        withAnimation(.spring(response: 0.42, dampingFraction: 0.84)) {
            detailSelection = nil
            pendingRunButton = button
            pendingRunReceipt = nil
            pendingRunEvents = []
            isPendingRunRunning = false
        }

        guard shouldStartImmediately(button) else {
            return
        }

        startPendingRun(
            button: button,
            prompt: defaultPrompt(for: button)
        )
    }

    private func confirmPendingRun(prompt: String) {
        guard let button = pendingRunButton else {
            return
        }

        startPendingRun(
            button: button,
            prompt: prompt
        )
    }

    private func savePendingRunPrompt(_ prompt: String) {
        guard var button = pendingRunButton else {
            return
        }

        if var firstStep = button.workflow.steps.first {
            firstStep.value = prompt
            button.workflow.steps[0] = firstStep
        }

        Task { @MainActor in
            await library.update(button)
            pendingRunButton = button
        }
    }

    private func cancelPendingRun() {
        if isPendingRunRunning {
            pendingRunTask?.cancel()
            return
        }

        withAnimation(.spring(response: 0.36, dampingFraction: 0.88)) {
            pendingRunButton = nil
            pendingRunReceipt = nil
            pendingRunEvents = []
            isPendingRunRunning = false
            pendingRunTask = nil
        }
    }

    private func startPendingRun(
        button: ActionButton,
        prompt: String
    ) {
        guard pendingRunTask == nil else {
            return
        }

        isPendingRunRunning = true
        pendingRunReceipt = nil
        pendingRunEvents = []
        pendingRunTask = Task {
            let receipt = await runNow(
                button,
                prompt: prompt,
                eventHandler: { event in
                    pendingRunEvents.append(event)
                }
            )
            pendingRunReceipt = receipt
            isPendingRunRunning = false
            pendingRunTask = nil
        }
    }

    @discardableResult
    private func runNow(
        _ button: ActionButton,
        prompt: String,
        eventHandler: ButtonRunEventHandler? = nil
    ) async -> ButtonRunReceipt {
        let currentButton = library.button(id: button.id) ?? button
        return await library.run(
            currentButton,
            prompt: prompt,
            configurationOverride: currentButton.workflow.steps.first?.aiConfiguration,
            eventHandler: eventHandler
        )
    }

    private func defaultPrompt(for button: ActionButton) -> String {
        button.workflow.steps.first?.value ?? button.taskDescription
    }

    private func shouldStartImmediately(_ button: ActionButton) -> Bool {
        !button.requiresRunConfirmation
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
                pendingRunTask?.cancel()
                pendingRunTask = nil
                pendingRunButton = nil
                pendingRunReceipt = nil
                pendingRunEvents = []
                isPendingRunRunning = false
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
