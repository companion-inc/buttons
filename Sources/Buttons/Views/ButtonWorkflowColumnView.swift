import AppKit
import ButtonsCore
import SwiftUI

struct ButtonWorkflowColumnView: View {
    @Environment(ButtonLibrary.self) private var library
    let button: ActionButton
    let closeAction: () -> Void
    let duplicateAction: (ActionButton) -> Void
    let shareAction: (ActionButton) -> Void
    let deleteAction: (ActionButton) -> Void

    @State private var draft: ButtonDraft
    @State private var latestReceipt: ButtonRunReceipt?
    @State private var runEvents: [String] = []
    @State private var isRunning = false
    @State private var runTask: Task<Void, Never>?
    @State private var showExecution = false
    @State private var titleIsAuto: Bool
    @State private var isNaming = false

    init(
        button: ActionButton,
        closeAction: @escaping () -> Void,
        duplicateAction: @escaping (ActionButton) -> Void,
        shareAction: @escaping (ActionButton) -> Void,
        deleteAction: @escaping (ActionButton) -> Void
    ) {
        self.button = button
        self.closeAction = closeAction
        self.duplicateAction = duplicateAction
        self.shareAction = shareAction
        self.deleteAction = deleteAction
        _draft = State(initialValue: ButtonDraft(button: button))

        let trimmedTitle = button.title.trimmingCharacters(in: .whitespacesAndNewlines)
        _titleIsAuto = State(initialValue: trimmedTitle.isEmpty || trimmedTitle == "New Button")
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                faceSection
                promptSection
                runSection
                executionSection
                logsSection
            }
            .padding(22)
            .frame(maxWidth: 940, alignment: .topLeading)
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .scrollIndicators(.hidden)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var faceSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 16) {
                faceEditor

                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .center, spacing: 10) {
                        DetailTextField(label: "Name", text: nameBinding)
                            .frame(maxWidth: 360)

                        if isNaming {
                            Label("Naming", systemImage: "text.badge.checkmark")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                                .transition(.opacity)
                        }
                    }

                    HStack(spacing: 12) {
                        DetailTextField(label: "Category", text: $draft.category)
                        DetailTextField(label: "Caption", text: $draft.subtitle)
                    }
                }

                Spacer(minLength: 14)

                topControls
            }
        }
        .padding(18)
        .background(Color.white.opacity(0.82))
        .clipShape(RoundedRectangle(cornerRadius: 30))
        .overlay(
            RoundedRectangle(cornerRadius: 30)
                .strokeBorder(.white.opacity(0.76), lineWidth: 1)
        )
        .shadow(color: draft.color.swiftUIColor.opacity(0.12), radius: 18, y: 10)
    }

    private var faceEditor: some View {
        HStack(spacing: 10) {
            Menu {
                ForEach(Self.symbolOptions, id: \.self) { symbol in
                    Button {
                        draft.symbolName = symbol
                    } label: {
                        Label(symbolTitle(symbol), systemImage: symbol)
                    }
                }
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(draft.color.swiftUIColor.gradient)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .strokeBorder(.white.opacity(0.42), lineWidth: 2)
                        )

                    Image(systemName: draft.symbolName)
                        .font(.title2.bold())
                        .foregroundStyle(draft.color.swiftUIForegroundColor)
                }
                .frame(width: 68, height: 68)
                .shadow(color: draft.color.swiftUIColor.opacity(0.20), radius: 12, y: 7)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Icon")
            .accessibilityHint("Choose this button's icon.")

            VStack(alignment: .leading, spacing: 8) {
                DetailMenuPicker(label: "Color", selection: $draft.color) {
                    ForEach(ButtonColor.allCases) { color in
                        Text(color.title).tag(color)
                    }
                }

                DetailMenuPicker(label: "Surface", selection: $draft.surface) {
                    ForEach(ButtonSurface.allCases) { surface in
                        Text(surface.title).tag(surface)
                    }
                }
            }
            .frame(width: 245)
        }
    }

    private var topControls: some View {
        HStack(spacing: 10) {
            Button(isRunning ? "Stop" : "Run", systemImage: isRunning ? "stop.fill" : "play.fill", action: run)
                .buttonStyle(AgentLaunchButtonStyle(color: isRunning ? .red : draft.color.swiftUIColor))
                .disabled(!canRun)
                .opacity(canRun ? 1 : 0.42)

            Menu {
                Button("Save", systemImage: "checkmark", action: save)
                Button("Share", systemImage: "square.and.arrow.up") {
                    shareAction(draft.button)
                }
                Button("Duplicate", systemImage: "plus.square.on.square") {
                    duplicateAction(draft.button)
                }
                Divider()
                Button("Delete", systemImage: "trash", role: .destructive) {
                    deleteAction(draft.button)
                }
            } label: {
                Label("More", systemImage: "ellipsis")
                    .labelStyle(.iconOnly)
                    .font(.headline.bold())
                    .frame(width: 44, height: 44)
                    .foregroundStyle(.white)
                    .background(.black.opacity(0.64))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .disabled(isRunning)
            .opacity(isRunning ? 0.42 : 1)

            Button("Done", systemImage: "checkmark", action: done)
                .buttonStyle(ChromePillButtonStyle(tint: .black.opacity(0.68)))
                .keyboardShortcut(.defaultAction)
                .disabled(isRunning)
                .opacity(isRunning ? 0.42 : 1)
        }
    }

    private var promptSection: some View {
        DetailCard(title: "Prompt") {
            DetailTextField(
                label: "What should this button do?",
                text: $draft.stepValue,
                axis: .vertical,
                minHeight: 220
            )
        }
    }

    private var runSection: some View {
        Group {
            if isRunning || !runEvents.isEmpty || latestReceipt != nil || !canRun {
                DetailCard(title: "State") {
                    if !canRun {
                        Label("Write the prompt to arm this button.", systemImage: "pencil")
                            .font(.callout.bold())
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 4)
                    } else if isRunning || !runEvents.isEmpty {
                        currentStateView
                    }

                    if let latestReceipt {
                        RunHistoryRow(receipt: latestReceipt)
                    }
                }
            }
        }
    }

    private var executionSection: some View {
        DetailCard(title: "Execution") {
            DisclosureGroup(isExpanded: $showExecution) {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 12) {
                        DetailMenuPicker(label: "Runner", selection: $draft.aiProvider) {
                            ForEach(AIProvider.allCases) { provider in
                                Text(provider.title).tag(provider)
                            }
                        }

                        DetailMenuPicker(label: "Permission", selection: $draft.aiExecutionMode) {
                            ForEach(AIExecutionMode.allCases) { mode in
                                Text(mode.title).tag(mode)
                            }
                        }
                    }

                    HStack(spacing: 12) {
                        DetailMenuPicker(label: "Thinking", selection: $draft.aiThinkingLevel) {
                            ForEach(AgentThinkingLevel.allCases) { level in
                                Text(level.title).tag(level)
                            }
                        }

                        DetailMenuPicker(label: "Run safety", selection: $draft.approvalPolicy) {
                            ForEach(ApprovalPolicy.allCases) { policy in
                                Text(policy.title).tag(policy)
                            }
                        }
                    }

                    DetailTextField(label: "Model override", text: $draft.aiModel)
                    DetailTextField(label: "Agent instruction", text: $draft.aiSystemPrompt, axis: .vertical, minHeight: 78)
                }
                .padding(.top, 12)
            } label: {
                HStack(spacing: 10) {
                    Label(executionSummary, systemImage: "terminal")
                        .font(.callout.bold())
                    Spacer()
                }
                .foregroundStyle(.primary)
            }
        }
    }

    private var logsSection: some View {
        DetailCard(title: "Runs") {
            let receipts = library.receipts(for: draft.button)
                .filter { receipt in
                    receipt.id != latestReceipt?.id
                }

            if receipts.isEmpty, latestReceipt == nil {
                Text("No runs yet.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
            } else {
                ForEach(receipts.prefix(5)) { receipt in
                    RunHistoryRow(receipt: receipt)
                }
            }
        }
    }

    private var currentStateView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(runEvents.last ?? "Starting.")
                .font(.callout.bold())
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            if runEvents.count > 1 {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(runEvents.suffix(5).enumerated()), id: \.offset) { _, event in
                        HStack(alignment: .top, spacing: 8) {
                            Circle()
                                .fill(draft.color.swiftUIColor.opacity(0.72))
                                .frame(width: 6, height: 6)
                                .padding(.top, 6)
                            Text(event)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.black.opacity(0.045))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var executionSummary: String {
        "\(draft.aiProvider.title), \(draft.aiExecutionMode.title), \(draft.aiThinkingLevel.title)"
    }

    private var canRun: Bool {
        !draft.stepValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var nameBinding: Binding<String> {
        Binding(
            get: { draft.title },
            set: { newValue in
                draft.title = newValue
                titleIsAuto = false
            }
        )
    }

    private func symbolTitle(_ symbol: String) -> String {
        symbol
            .replacingOccurrences(of: ".fill", with: "")
            .replacingOccurrences(of: ".", with: " ")
            .capitalized
    }

    private func save() {
        Task {
            await saveDraft()
        }
    }

    private func done() {
        Task {
            await saveDraft()
            closeAction()
        }
    }

    private func run() {
        if isRunning {
            runTask?.cancel()
            return
        }

        guard canRun else {
            return
        }

        isRunning = true
        runEvents = []
        runTask = Task {
            await saveDraft()
            let currentButton = draft.button
            let receipt = await library.run(
                currentButton,
                prompt: currentButton.workflow.steps.first?.value ?? "",
                configurationOverride: currentButton.workflow.steps.first?.aiConfiguration,
                eventHandler: { event in
                    runEvents.append(event)
                }
            )
            latestReceipt = receipt
            isRunning = false
            runTask = nil

            guard receipt.status != .canceled else { return }

            await applyAutoMetadataIfNeeded()
            await upsertDraftButton()
        }
    }

    private func saveDraft() async {
        await upsertDraftButton()
        await applyAutoMetadataIfNeeded()
        await upsertDraftButton()
    }

    private func upsertDraftButton() async {
        await upsert(draft.button)
    }

    private func upsert(_ button: ActionButton) async {
        if library.button(id: button.id) == nil {
            await library.add(button)
        } else {
            await library.update(button)
        }
    }

    private func applyAutoMetadataIfNeeded() async {
        guard titleIsAuto else { return }

        let prompt = draft.stepValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty, prompt != Self.seedPrompt else { return }

        isNaming = true
        defer { isNaming = false }

        guard let meta = await library.deriveMetadata(forPrompt: prompt, provider: draft.aiProvider) else {
            return
        }

        draft.title = meta.name
        draft.slug = ButtonWorkspaceSlug.make(from: meta.name)

        let category = draft.category.trimmingCharacters(in: .whitespacesAndNewlines)
        if !meta.category.isEmpty, category.isEmpty || category == "General" {
            draft.category = meta.category
        }

        let goal = draft.taskDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        if !meta.goal.isEmpty, goal.isEmpty || goal == Self.seedTaskDescription {
            draft.taskDescription = meta.goal
        }

        if draft.color == .poppy, let raw = meta.colorRawValue, let color = ButtonColor(rawValue: raw) {
            draft.color = color
        }

        if draft.symbolName == Self.seedSymbol, let symbol = meta.symbolName, Self.isValidSymbol(symbol) {
            draft.symbolName = symbol
        }

        titleIsAuto = false
    }

    private static func isValidSymbol(_ name: String) -> Bool {
        NSImage(systemSymbolName: name, accessibilityDescription: nil) != nil
    }

    private static let seedPrompt = "Do this repetitive workflow end to end."
    private static let seedTaskDescription = "Do the repetitive task."
    private static let seedSymbol = "button.programmable"

    private static let symbolOptions = [
        "button.programmable",
        "star.fill",
        "terminal.fill",
        "calendar",
        "tray.full.fill",
        "paperplane.fill",
        "hammer.fill",
        "paintbrush.fill",
        "bolt.fill",
        "checklist",
        "doc.text.fill",
        "link",
    ]
}
