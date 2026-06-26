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
    @State private var showSettings = false
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

        // A fresh button keeps deriving its name from the prompt until the user
        // renames it by hand. An existing, already-named button keeps its name.
        let trimmedTitle = button.title.trimmingCharacters(in: .whitespacesAndNewlines)
        _titleIsAuto = State(initialValue: trimmedTitle.isEmpty || trimmedTitle == "New Button")
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                promptSection
                runSection
                settingsSection
                logsSection
            }
            .padding(22)
            .frame(maxWidth: 920, alignment: .topLeading)
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .scrollIndicators(.hidden)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var header: some View {
        HStack(spacing: 14) {
            Image(systemName: draft.symbolName)
                .font(.title2)
                .frame(width: 54, height: 54)
                .foregroundStyle(draft.color.swiftUIForegroundColor)
                .background(draft.color.swiftUIColor.gradient)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(draft.title)
                        .font(.title2.bold())
                        .lineLimit(1)

                    if isNaming {
                        HStack(spacing: 5) {
                            ProgressView()
                                .controlSize(.small)
                            Text("Naming…")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.secondary)
                        }
                        .transition(.opacity)
                    }
                }
                HStack(spacing: 8) {
                    Text(draft.category)
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.black.opacity(0.06))
                        .clipShape(Capsule())

                    AgentBadgeView(provider: draft.aiProvider)
                    AutomationStatusBadgeView(button: draft.button)
                }
            }

            Spacer()

            Button("Close", systemImage: "xmark", action: closeAction)
                .labelStyle(.iconOnly)
                .buttonStyle(.plain)
                .font(.headline)
                .padding(10)
                .background(.black.opacity(0.06))
                .clipShape(Circle())
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
                minHeight: 200
            )
        }
    }

    private var settingsSection: some View {
        DetailCard(title: "Settings") {
            DisclosureGroup(isExpanded: $showSettings) {
                VStack(alignment: .leading, spacing: 16) {
                    settingsGroup("Button") {
                        HStack(spacing: 12) {
                            DetailTextField(label: "Name", text: nameBinding)
                            DetailTextField(label: "Category", text: $draft.category)
                        }

                        HStack(spacing: 12) {
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
                    }

                    settingsGroup("Agent") {
                        HStack(spacing: 12) {
                            DetailMenuPicker(label: "Runner", selection: $draft.aiProvider) {
                                ForEach(AIProvider.allCases) { provider in
                                    Text(provider.title).tag(provider)
                                }
                            }

                            DetailMenuPicker(label: "Thinking", selection: $draft.aiThinkingLevel) {
                                ForEach(AgentThinkingLevel.allCases) { level in
                                    Text(level.title).tag(level)
                                }
                            }
                        }

                        HStack(spacing: 12) {
                            DetailMenuPicker(label: "Permission", selection: $draft.aiExecutionMode) {
                                ForEach(AIExecutionMode.allCases) { mode in
                                    Text(mode.title).tag(mode)
                                }
                            }

                            DetailMenuPicker(label: "Run safety", selection: $draft.approvalPolicy) {
                                ForEach(ApprovalPolicy.allCases) { policy in
                                    Text(policy.title).tag(policy)
                                }
                            }
                        }
                    }

                    settingsGroup("Advanced") {
                        DetailTextField(label: "Goal summary", text: $draft.taskDescription)
                        DetailTextField(label: "Workspace slug", text: $draft.slug)
                        DetailTextField(label: "Caption", text: $draft.subtitle)
                        DetailTextField(label: "Symbol", text: $draft.symbolName)
                        DetailTextField(label: "Model", text: $draft.aiModel)
                        DetailTextField(label: "Agent instruction", text: $draft.aiSystemPrompt, axis: .vertical, minHeight: 78)
                    }
                }
                .padding(.top, 12)
            } label: {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Name, agent, color, permissions")
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(.primary)
                }
            }
        }
    }

    @ViewBuilder
    private func settingsGroup<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            content()
        }
    }

    private var nameBinding: Binding<String> {
        Binding(
            get: { draft.title },
            set: { newValue in
                draft.title = newValue
                // Once the user types a name, stop overwriting it from the prompt.
                titleIsAuto = false
            }
        )
    }

    /// Runs once, when the user saves or runs a still-unnamed button: a small
    /// read-only model reads the prompt and fills the name, category, goal, color,
    /// and icon. Only fields the user hasn't customized are touched, so a manual
    /// name in Settings always wins. Falls back to nothing if the model is offline.
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

    private var runSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Button("Save", systemImage: "checkmark", action: save)
                    .buttonStyle(ChromePillButtonStyle(tint: .black.opacity(0.66)))
                    .keyboardShortcut("s", modifiers: .command)
                    .disabled(isRunning)
                    .opacity(isRunning ? 0.42 : 1)

                Spacer()

                Button("Share", systemImage: "square.and.arrow.up") {
                    shareAction(draft.button)
                }
                .buttonStyle(ChromePillButtonStyle(tint: .black.opacity(0.52)))
                .disabled(isRunning)
                .opacity(isRunning ? 0.42 : 1)

                Button("Duplicate", systemImage: "plus.square.on.square") {
                    duplicateAction(draft.button)
                }
                .buttonStyle(ChromePillButtonStyle(tint: .black.opacity(0.52)))
                .disabled(isRunning)
                .opacity(isRunning ? 0.42 : 1)

                Button("Delete", systemImage: "trash", role: .destructive) {
                    deleteAction(draft.button)
                }
                .buttonStyle(ChromePillButtonStyle(tint: .red.opacity(0.82)))
                .disabled(isRunning)
                .opacity(isRunning ? 0.42 : 1)

                Button(isRunning ? "Stop" : "Run", systemImage: isRunning ? "stop.fill" : "play.fill", action: run)
                    .buttonStyle(AgentLaunchButtonStyle(color: isRunning ? .red : draft.color.swiftUIColor))
            }
        }
    }

    private var logsSection: some View {
        DetailCard(title: "Runs") {
            if isRunning || !runEvents.isEmpty {
                currentStateView
            }

            if let latestReceipt {
                RunHistoryRow(receipt: latestReceipt)
            }

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
                ForEach(receipts.prefix(4)) { receipt in
                    RunHistoryRow(receipt: receipt)
                }
            }
        }
    }

    private var currentStateView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Current state")
                .font(.caption.bold())
                .foregroundStyle(.secondary)

            Text(runEvents.last ?? "Starting.")
                .font(.callout.weight(.semibold))
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
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func save() {
        Task {
            await upsertDraftButton()
            await applyAutoMetadataIfNeeded()
            await upsertDraftButton()
        }
    }

    private func run() {
        if isRunning {
            runTask?.cancel()
            return
        }

        isRunning = true
        runEvents = []
        runTask = Task {
            let currentButton = draft.button
            await upsert(currentButton)
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

}
