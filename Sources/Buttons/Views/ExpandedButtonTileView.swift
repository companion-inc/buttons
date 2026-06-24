import ButtonsCore
import SwiftUI

struct ExpandedButtonTileView: View {
    let button: ActionButton
    let closeAction: () -> Void
    let duplicateAction: (ActionButton) -> Void
    let shareAction: (ActionButton) -> Void
    let deleteAction: (ActionButton) -> Void

    var body: some View {
        ButtonWorkflowColumnView(
            button: button,
            closeAction: closeAction,
            duplicateAction: duplicateAction,
            shareAction: shareAction,
            deleteAction: deleteAction
        )
        .frame(maxWidth: .infinity)
    }
}
