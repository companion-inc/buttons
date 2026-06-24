import ButtonsCore
import SwiftUI

struct ButtonBoardView: View {
    let buttons: [ActionButton]
    let selectedButtonID: UUID?
    let namespace: Namespace.ID
    let runAction: (ActionButton) -> Void
    let editAction: (ActionButton) -> Void
    let duplicateAction: (ActionButton) -> Void
    let shareAction: (ActionButton) -> Void
    let runsAction: (ActionButton) -> Void
    let deleteAction: (ActionButton) -> Void

    private let columns = [
        GridItem(.adaptive(minimum: 220, maximum: 320), spacing: 22),
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 22) {
                ForEach(buttons) { button in
                    if selectedButtonID == button.id {
                        Color.clear
                            .frame(maxWidth: .infinity, minHeight: 196)
                    } else {
                        ButtonTileView(
                            button: button,
                            isSelected: false,
                            runAction: runAction,
                            editAction: editAction,
                            duplicateAction: duplicateAction,
                            shareAction: shareAction,
                            runsAction: runsAction,
                            deleteAction: deleteAction
                        )
                        .matchedGeometryEffect(
                            id: "button-\(button.id.uuidString)",
                            in: namespace,
                            properties: .frame,
                            isSource: true
                        )
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .scrollIndicators(.hidden)
    }
}
