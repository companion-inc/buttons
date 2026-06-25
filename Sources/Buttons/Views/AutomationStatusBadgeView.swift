import ButtonsCore
import SwiftUI

struct AutomationStatusBadgeView: View {
    let button: ActionButton

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: isOptimized ? "checkmark.seal.fill" : "bolt.fill")
                .font(.caption.bold())
                .accessibilityHidden(true)

            Text(isOptimized ? "Optimized" : "Learning")
                .font(.caption.bold())
        }
        .foregroundStyle(isOptimized ? .green : .secondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background((isOptimized ? Color.green : Color.black).opacity(isOptimized ? 0.12 : 0.08))
        .clipShape(Capsule())
    }

    private var isOptimized: Bool {
        ButtonAutomationWorkspace.production().automationExists(for: button)
    }
}
