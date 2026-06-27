import ButtonsCore
import SwiftUI

struct ButtonTileView: View {
    let button: ActionButton
    let isSelected: Bool
    let isRunning: Bool
    let latestReceipt: ButtonRunReceipt?
    let runAction: (ActionButton) -> Void
    let editAction: (ActionButton) -> Void
    let duplicateAction: (ActionButton) -> Void
    let shareAction: (ActionButton) -> Void
    let runsAction: (ActionButton) -> Void
    let deleteAction: (ActionButton) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            topRail
            pressActuator
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 226, alignment: .topLeading)
        .background(baseBackground)
        .clipShape(RoundedRectangle(cornerRadius: 38))
        .overlay(selectionStroke)
        .shadow(color: button.face.color.swiftUIColor.opacity(0.16), radius: 22, y: 14)
        .contextMenu {
            Button("Open", systemImage: "arrow.up.left.and.arrow.down.right") {
                editAction(button)
            }
            Button("Runs", systemImage: "clock.arrow.circlepath") {
                runsAction(button)
            }
            Button("Duplicate", systemImage: "plus.square.on.square") {
                duplicateAction(button)
            }
            Button("Share", systemImage: "square.and.arrow.up") {
                shareAction(button)
            }
            Divider()
            Button("Delete", systemImage: "trash", role: .destructive) {
                deleteAction(button)
            }
        }
    }

    private var topRail: some View {
        HStack(spacing: 8) {
            statusBadge
            Spacer(minLength: 8)
            enterButton
        }
    }

    private var pressActuator: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                openFaceButton
                Spacer(minLength: 10)
                runButton
            }

            Spacer(minLength: 4)

            Button(action: open) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(button.title)
                        .font(.title3)
                        .bold()
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    Text(subtitle)
                        .font(.callout)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .opacity(0.82)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Open \(button.title)")
            .accessibilityHint("Opens this button's prompt, face, execution details, and run history.")
        }
        .padding(22)
        .frame(maxWidth: .infinity, minHeight: 162, alignment: .leading)
        .physicalButtonSurface(face: button.face)
        .opacity(canRun ? 1 : 0.72)
    }

    private var openFaceButton: some View {
        Button(action: open) {
            Image(systemName: button.face.symbolName)
                .font(.title2)
                .symbolRenderingMode(.hierarchical)
                .frame(width: 48, height: 48)
                .background(iconBackground)
                .clipShape(RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open \(button.title)")
        .accessibilityHint("Opens this button's prompt, face, execution details, and run history.")
        .help("Open")
    }

    private var runButton: some View {
        Button(action: run) {
            Label(runButtonTitle, systemImage: isRunning ? "waveform" : "play.fill")
                .labelStyle(.iconOnly)
                .font(.title3.bold())
                .frame(width: 50, height: 50)
                .background(.white.opacity(button.face.color == .paper || button.face.color == .lemon ? 0.40 : 0.24))
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .strokeBorder(.white.opacity(0.28), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.12), radius: 7, y: 4)
        }
        .buttonStyle(.plain)
        .disabled(!canRun)
        .opacity(canRun ? 1 : 0.44)
        .accessibilityHint(runHint)
        .help(runButtonTitle)
    }

    private var enterButton: some View {
        Button("Open", systemImage: "arrow.up.left.and.arrow.down.right") {
            editAction(button)
        }
        .labelStyle(.iconOnly)
        .buttonStyle(.plain)
        .font(.headline.bold())
        .foregroundStyle(.primary.opacity(0.74))
        .frame(width: 42, height: 42)
        .background(.white.opacity(0.62))
        .clipShape(Circle())
        .overlay(
            Circle()
                .strokeBorder(.black.opacity(0.06), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.08), radius: 7, y: 4)
        .accessibilityHint("Opens this button's prompt, face, execution details, and run history.")
    }

    private var statusBadge: some View {
        Label(statusTitle, systemImage: statusSymbol)
            .font(.caption.bold())
            .lineLimit(1)
            .foregroundStyle(statusColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(.white.opacity(0.62))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(.black.opacity(0.06), lineWidth: 1)
            )
    }

    private var selectionStroke: some View {
        RoundedRectangle(cornerRadius: 38)
            .strokeBorder(isSelected ? Color.black.opacity(0.42) : Color.clear, lineWidth: 3)
    }

    private var baseBackground: some ShapeStyle {
        LinearGradient(
            colors: [
                Color.white.opacity(0.82),
                button.face.color.swiftUIColor.opacity(0.16),
                Color.white.opacity(0.56),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var iconBackground: some ShapeStyle {
        AnyShapeStyle(.white.opacity(button.face.color == .paper || button.face.color == .lemon ? 0.44 : 0.24))
    }

    private var subtitle: String {
        if isRunning {
            return "Running now"
        }

        if !canRun {
            return "Write the prompt inside"
        }

        return button.subtitle.isEmpty ? button.taskDescription : button.subtitle
    }

    private var runHint: String {
        if isRunning {
            return "Shows the live run state for this button."
        }

        return canRun ? "Runs this saved prompt." : "Add a prompt before this button can run."
    }

    private var runButtonTitle: String {
        if isRunning {
            return "Show run"
        }

        return canRun ? "Run" : "Add prompt before running"
    }

    private var statusTitle: String {
        if isRunning {
            return "Running"
        }

        guard canRun else {
            return "Draft"
        }

        switch latestReceipt?.status {
        case .succeeded:
            return "Done"
        case .failed:
            return "Failed"
        case .canceled:
            return "Stopped"
        case nil:
            return button.category
        }
    }

    private var statusSymbol: String {
        if isRunning {
            return "waveform"
        }

        guard canRun else {
            return "pencil"
        }

        switch latestReceipt?.status {
        case .succeeded:
            return "checkmark.circle.fill"
        case .failed:
            return "xmark.octagon.fill"
        case .canceled:
            return "stop.circle.fill"
        case nil:
            return "tag.fill"
        }
    }

    private var statusColor: Color {
        if isRunning {
            return button.face.color.swiftUIColor
        }

        guard canRun else {
            return .secondary
        }

        switch latestReceipt?.status {
        case .succeeded:
            return .green
        case .failed:
            return .red
        case .canceled:
            return .secondary
        case nil:
            return .primary.opacity(0.72)
        }
    }

    private var canRun: Bool {
        let value = button.workflow.steps.first?.value.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return !value.isEmpty && value != Self.seedPrompt
    }

    private static let seedPrompt = "Do this repetitive workflow end to end."

    private func run() {
        runAction(button)
    }

    private func open() {
        editAction(button)
    }
}
