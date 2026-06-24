import ButtonsCore
import SwiftUI

struct ButtonBoardView: View {
    let buttons: [ActionButton]
    let runAction: (ActionButton) -> Void
    let editAction: (ActionButton) -> Void
    let duplicateAction: (ActionButton) -> Void
    let shareAction: (ActionButton) -> Void
    let deleteAction: (ActionButton) -> Void

    private let columns = [
        GridItem(.adaptive(minimum: 190, maximum: 260), spacing: 18),
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 18) {
                ForEach(buttons) { button in
                    ButtonTileView(
                        button: button,
                        runAction: runAction,
                        editAction: editAction,
                        duplicateAction: duplicateAction,
                        shareAction: shareAction,
                        deleteAction: deleteAction
                    )
                }
            }
            .padding(.vertical, 4)
        }
        .scrollIndicators(.hidden)
    }
}
