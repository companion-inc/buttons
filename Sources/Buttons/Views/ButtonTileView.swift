import ButtonsCore
import SwiftUI

struct ButtonTileView: View {
    let button: ActionButton
    let isSelected: Bool
    let runAction: (ActionButton) -> Void
    let editAction: (ActionButton) -> Void
    let duplicateAction: (ActionButton) -> Void
    let shareAction: (ActionButton) -> Void
    let runsAction: (ActionButton) -> Void
    let deleteAction: (ActionButton) -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Button {
                runAction(button)
            } label: {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Image(systemName: button.face.symbolName)
                            .font(.title2)
                            .symbolRenderingMode(.hierarchical)
                            .frame(width: 44, height: 44)
                            .background(iconBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .accessibilityHidden(true)

                        Spacer()
                    }

                    Spacer(minLength: 8)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(button.title)
                            .font(.title3)
                            .bold()
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)

                        Text(button.subtitle)
                            .font(.callout)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }

                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 8) {
                            categoryBadge
                            AgentBadgeView(provider: provider)
                            ScriptStatusBadgeView(buttonID: button.id)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {
                                categoryBadge
                                AgentBadgeView(provider: provider)
                            }
                            ScriptStatusBadgeView(buttonID: button.id)
                        }
                    }
                }
                .padding(22)
                .frame(maxWidth: .infinity, minHeight: 196, alignment: .leading)
                .contentShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
            }
            .buttonStyle(PhysicalButtonTileStyle(face: button.face))
            .overlay(
                RoundedRectangle(cornerRadius: 38, style: .continuous)
                    .strokeBorder(isSelected ? Color.black.opacity(0.42) : Color.clear, lineWidth: 3)
                    .padding(-2)
            )

            Button("Settings", systemImage: "gearshape.fill") {
                editAction(button)
            }
            .labelStyle(.iconOnly)
            .buttonStyle(.plain)
            .font(.headline)
            .foregroundStyle(button.face.color.swiftUIForegroundColor)
            .frame(width: 38, height: 38)
            .background(.white.opacity(button.face.color == .paper || button.face.color == .lemon ? 0.34 : 0.22))
            .clipShape(Circle())
            .padding(18)
            .accessibilityLabel("Settings")
        }
        .contextMenu {
            Button("Edit", systemImage: "slider.horizontal.3") {
                editAction(button)
            }
            Button("Duplicate", systemImage: "plus.square.on.square") {
                duplicateAction(button)
            }
            Button("Share", systemImage: "square.and.arrow.up") {
                shareAction(button)
            }
            Button("Runs", systemImage: "clock.arrow.circlepath") {
                runsAction(button)
            }
            Divider()
            Button("Delete", systemImage: "trash", role: .destructive) {
                deleteAction(button)
            }
        }
        .accessibilityLabel(button.title)
        .accessibilityHint(button.taskDescription)
    }

    private var iconBackground: some ShapeStyle {
        AnyShapeStyle(.white.opacity(button.face.color == .paper || button.face.color == .lemon ? 0.4 : 0.2))
    }

    private var provider: AIProvider {
        button.workflow.steps.first?.aiConfiguration?.provider ?? .codex
    }

    private var categoryBadge: some View {
        Text(button.category)
            .font(.caption.bold())
            .lineLimit(1)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.black.opacity(button.face.color == .paper || button.face.color == .lemon ? 0.08 : 0.18))
            .clipShape(Capsule())
    }
}
