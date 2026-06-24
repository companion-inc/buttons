import ButtonsCore
import SwiftUI

struct ButtonDetailScreenView: View {
    let button: ActionButton
    let namespace: Namespace.ID
    let closeAction: () -> Void
    let duplicateAction: (ActionButton) -> Void
    let shareAction: (ActionButton) -> Void
    let deleteAction: (ActionButton) -> Void

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 42, style: .continuous)
                .fill(Color(red: 0.96, green: 0.96, blue: 0.94))
                .matchedGeometryEffect(
                    id: "button-\(button.id.uuidString)",
                    in: namespace,
                    properties: .frame,
                    isSource: false
                )
                .shadow(color: button.face.color.swiftUIColor.opacity(0.24), radius: 36, y: 22)

            RoundedRectangle(cornerRadius: 42, style: .continuous)
                .fill(baseBackground)

            ButtonWorkflowColumnView(
                button: button,
                closeAction: closeAction,
                duplicateAction: duplicateAction,
                shareAction: shareAction,
                deleteAction: deleteAction
            )
            .padding(24)
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var baseBackground: some ShapeStyle {
        LinearGradient(
            colors: [
                Color.white,
                button.face.color.swiftUIColor.opacity(0.10),
                Color(red: 0.92, green: 0.94, blue: 0.97),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
