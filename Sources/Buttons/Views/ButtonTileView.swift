import ButtonsCore
import SwiftUI

struct ButtonTileView: View {
    let button: ActionButton
    let runAction: (ActionButton) -> Void
    let editAction: (ActionButton) -> Void
    let duplicateAction: (ActionButton) -> Void
    let shareAction: (ActionButton) -> Void
    let deleteAction: (ActionButton) -> Void

    var body: some View {
        Button {
            runAction(button)
        } label: {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Image(systemName: button.face.symbolName)
                        .font(.title2)
                        .symbolRenderingMode(.hierarchical)
                        .frame(width: 38, height: 38)
                        .background(iconBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .accessibilityHidden(true)

                    Spacer()

                    Image(systemName: button.needsApproval ? "lock" : "bolt.fill")
                        .font(.body)
                        .accessibilityHidden(true)
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

                Text(button.workflow.steps.first?.kind.title ?? "Task")
                    .font(.caption)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(.black.opacity(button.face.color == .paper || button.face.color == .lemon ? 0.08 : 0.18))
                    .clipShape(Capsule())
            }
            .foregroundStyle(button.face.color.swiftUIForegroundColor)
            .padding(18)
            .frame(maxWidth: .infinity, minHeight: 174, alignment: .leading)
            .background(tileBackground)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(tileStroke)
            .shadow(color: shadowColor, radius: 16, y: 10)
        }
        .buttonStyle(.plain)
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
            Divider()
            Button("Delete", systemImage: "trash", role: .destructive) {
                deleteAction(button)
            }
        }
        .accessibilityLabel(button.title)
        .accessibilityHint(button.taskDescription)
    }

    private var tileBackground: some ShapeStyle {
        switch button.face.surface {
        case .raised:
            AnyShapeStyle(
                LinearGradient(
                    colors: [
                        button.face.color.swiftUIColor.opacity(0.96),
                        button.face.color.swiftUIColor.opacity(0.82),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        case .rubber:
            AnyShapeStyle(button.face.color.swiftUIColor)
        case .metal:
            AnyShapeStyle(
                LinearGradient(
                    colors: [
                        button.face.color.swiftUIColor.opacity(0.96),
                        Color.white.opacity(0.12),
                        button.face.color.swiftUIColor.opacity(0.86),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        case .glass:
            AnyShapeStyle(button.face.color.swiftUIColor.opacity(0.74))
        case .terminal:
            AnyShapeStyle(
                LinearGradient(
                    colors: [Color.black, button.face.color.swiftUIColor.opacity(0.76)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
    }

    private var tileStroke: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .strokeBorder(.white.opacity(button.face.surface == .glass ? 0.48 : 0.18), lineWidth: 1)
    }

    private var iconBackground: some ShapeStyle {
        AnyShapeStyle(.white.opacity(button.face.color == .paper || button.face.color == .lemon ? 0.4 : 0.2))
    }

    private var shadowColor: Color {
        Color.black.opacity(button.face.surface == .terminal ? 0.28 : 0.16)
    }

    private var cornerRadius: CGFloat {
        button.face.surface == .rubber ? 7 : 8
    }
}
