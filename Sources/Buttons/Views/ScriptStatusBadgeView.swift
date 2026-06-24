import ButtonsCore
import SwiftUI

struct ScriptStatusBadgeView: View {
    let button: ActionButton

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: isScriptReady ? "checkmark.seal.fill" : "hammer.fill")
                .font(.caption.bold())
                .accessibilityHidden(true)

            Text(isScriptReady ? "Script ready" : "Build script")
                .font(.caption.bold())
        }
        .foregroundStyle(isScriptReady ? .green : .secondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background((isScriptReady ? Color.green : Color.black).opacity(isScriptReady ? 0.12 : 0.08))
        .clipShape(Capsule())
    }

    private var isScriptReady: Bool {
        ButtonAutomationWorkspace.production().scriptExists(for: button)
    }
}
