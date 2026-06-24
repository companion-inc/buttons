import ButtonsCore
import SwiftUI

struct ButtonEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ButtonLibrary.self) private var library
    @State private var draft: ButtonDraft

    init(_ button: ActionButton) {
        _draft = State(initialValue: ButtonDraft(button: button))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Face") {
                    TextField("Name", text: $draft.title)
                    TextField("Caption", text: $draft.subtitle)
                    TextField("Symbol", text: $draft.symbolName)

                    Picker("Color", selection: $draft.color) {
                        ForEach(ButtonColor.allCases) { color in
                            Text(color.title).tag(color)
                        }
                    }

                    Picker("Surface", selection: $draft.surface) {
                        ForEach(ButtonSurface.allCases) { surface in
                            Text(surface.title).tag(surface)
                        }
                    }
                }

                Section("Task") {
                    TextField("What it does", text: $draft.taskDescription, axis: .vertical)
                        .lineLimit(2...4)

                    Picker("Action", selection: $draft.stepKind) {
                        ForEach(WorkflowStepKind.allCases) { kind in
                            Text(kind.title).tag(kind)
                        }
                    }

                    TextField(draft.stepKind.valueLabel, text: $draft.stepValue, axis: .vertical)
                        .lineLimit(3...8)

                    Picker("Approval", selection: $draft.approvalPolicy) {
                        ForEach(ApprovalPolicy.allCases) { policy in
                            Text(policy.title).tag(policy)
                        }
                    }
                }

                Section("Input") {
                    TextField("Key", text: $draft.inputKey)
                    TextField("Label", text: $draft.inputLabel)
                    TextField("Default", text: $draft.inputDefault)
                }

                Section("Permissions") {
                    TextField("Permission", text: $draft.permissionTitle)
                    TextField("Detail", text: $draft.permissionDetail, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .formStyle(.grouped)
            .navigationTitle(draft.title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: dismiss.callAsFunction)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .frame(width: 520, height: 660)
    }

    private func save() {
        let button = draft.button
        Task {
            if library.button(id: button.id) == nil {
                await library.add(button)
            } else {
                await library.update(button)
            }
            dismiss()
        }
    }
}
