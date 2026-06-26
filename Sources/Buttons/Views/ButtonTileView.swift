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

                        ButtonTileControlMark(systemName: "gearshape.fill", face: button.face, size: 38)
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

                    HStack(alignment: .bottom, spacing: 10) {
                        categoryBadge
                            .frame(maxWidth: .infinity, alignment: .leading)

                        ButtonTileControlMark(systemName: "play.fill", face: button.face, size: 52, font: .title3)
                            .layoutPriority(2)
                    }
                }
                .padding(22)
                .frame(maxWidth: .infinity, minHeight: 196, alignment: .leading)
                .contentShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
            }
            .buttonStyle(PhysicalButtonTileStyle(face: button.face))
            .accessibilityLabel(button.title)
            .accessibilityHint("Runs \(button.taskDescription)")
            .overlay(
                RoundedRectangle(cornerRadius: 38, style: .continuous)
                    .strokeBorder(isSelected ? Color.black.opacity(0.42) : Color.clear, lineWidth: 3)
                    .padding(-2)
            )

            Button {
                editAction(button)
            } label: {
                Color.clear
                    .frame(width: 52, height: 52)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .padding(11)
            .accessibilityLabel("Settings for \(button.title)")
            .accessibilityHint("Opens button settings")
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
    }

    private var iconBackground: some ShapeStyle {
        AnyShapeStyle(.white.opacity(button.face.color == .paper || button.face.color == .lemon ? 0.4 : 0.2))
    }

    private var categoryBadge: some View {
        Text(button.category)
            .font(.caption.bold())
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.black.opacity(button.face.color == .paper || button.face.color == .lemon ? 0.08 : 0.18))
            .clipShape(Capsule())
            .fixedSize(horizontal: true, vertical: false)
    }

}
