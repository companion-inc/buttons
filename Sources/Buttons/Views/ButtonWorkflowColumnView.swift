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
    @State private var values: [String: String]
    @State private var latestReceipt: ButtonRunReceipt?
    @State private var isRunning = false
    @State private var showAdvanced = false

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
        _values = State(initialValue: Dictionary(uniqueKeysWithValues: button.workflow.inputs.map { ($0.key, $0.defaultValue) }))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                workflowSection
                agentSection
                buttonSection
                advancedSection
                runSection
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
                Text(draft.title)
                    .font(.title2.bold())
                    .lineLimit(1)
                HStack(spacing: 8) {
                    Text(draft.category)
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.black.opacity(0.06))
                        .clipShape(Capsule())

                    AgentBadgeView(provider: draft.aiProvider)
                    ScriptStatusBadgeView(buttonID: draft.id)
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
        }
    }

    private var workflowSection: some View {
        DetailCard(title: "Workflow") {
            DetailTextField(label: "Goal", text: $draft.taskDescription, axis: .vertical)
                .lineLimit(2...4)
            DetailTextField(label: "Steps", text: $draft.stepValue, axis: .vertical)
                .lineLimit(6...12)
        }
    }

    private var agentSection: some View {
        DetailCard(title: "Agent") {
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

                DetailMenuPicker(label: "Permission", selection: $draft.aiExecutionMode) {
                    ForEach(AIExecutionMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
            }
        }
    }

    private var buttonSection: some View {
        DetailCard(title: "Button") {
            HStack(spacing: 12) {
                DetailTextField(label: "Name", text: $draft.title)
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

                DetailMenuPicker(label: "Confirm", selection: $draft.approvalPolicy) {
                    ForEach(ApprovalPolicy.allCases) { policy in
                        Text(policy.title).tag(policy)
                    }
                }
            }
        }
    }

    private var advancedSection: some View {
        DetailCard(title: "Advanced") {
            DisclosureGroup(isExpanded: $showAdvanced) {
                VStack(alignment: .leading, spacing: 12) {
                    DetailTextField(label: "Caption", text: $draft.subtitle)
                    DetailTextField(label: "Symbol", text: $draft.symbolName)
                    DetailTextField(label: "Model", text: $draft.aiModel)
                    DetailTextField(label: "Directory", text: $draft.aiWorkingDirectory)
                    DetailTextField(label: "Agent instruction", text: $draft.aiSystemPrompt, axis: .vertical)
                        .lineLimit(2...4)

                    Divider()

                    DetailTextField(label: "Input key", text: $draft.inputKey)
                    DetailTextField(label: "Input label", text: $draft.inputLabel)
                    DetailTextField(label: "Input default", text: $draft.inputDefault)
                }
                .padding(.top, 10)
            } label: {
                Text("Model, directory, icon, and per-run input")
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(.primary)
            }
        }
    }

    private var runSection: some View {
        VStack(spacing: 12) {
            if !button.workflow.inputs.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(button.workflow.inputs) { input in
                        DetailTextField(
                            label: input.label,
                            text: valueBinding(for: input)
                        )
                    }
                }
            }

            HStack(spacing: 10) {
                Button("Save", systemImage: "checkmark", action: save)
                    .buttonStyle(ChromePillButtonStyle(tint: .black.opacity(0.66)))

                Spacer()

                Button("Share", systemImage: "square.and.arrow.up") {
                    shareAction(draft.button)
                }
                .buttonStyle(ChromePillButtonStyle(tint: .black.opacity(0.52)))

                Button("Duplicate", systemImage: "plus.square.on.square") {
                    duplicateAction(draft.button)
                }
                .buttonStyle(ChromePillButtonStyle(tint: .black.opacity(0.52)))

                Button("Delete", systemImage: "trash", role: .destructive) {
                    deleteAction(draft.button)
                }
                .buttonStyle(ChromePillButtonStyle(tint: .red.opacity(0.82)))

                Button(isRunning ? "Running..." : "Run \(draft.aiProvider.shortTitle)", systemImage: "play.fill", action: run)
                    .buttonStyle(AgentLaunchButtonStyle(color: draft.color.swiftUIColor))
                    .disabled(isRunning)
            }
        }
    }

    private var logsSection: some View {
        DetailCard(title: "Runs") {
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

    private func save() {
        Task {
            await upsertDraftButton()
        }
    }

    private func run() {
        isRunning = true
        Task {
            let currentButton = draft.button
            await upsert(currentButton)
            let receipt = await library.run(
                currentButton,
                values: values,
                configurationOverride: currentButton.workflow.steps.first?.aiConfiguration
            )
            latestReceipt = receipt
            isRunning = false
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

    private func valueBinding(for input: ButtonInputField) -> Binding<String> {
        Binding(
            get: { values[input.key, default: input.defaultValue] },
            set: { values[input.key] = $0 }
        )
    }
}
