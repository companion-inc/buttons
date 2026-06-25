import ButtonsCore
import SwiftUI

struct AutomationStatusBadgeView: View {
    let button: ActionButton

    @ViewBuilder
    var body: some View {
        if isOptimized {
            HStack(spacing: 6) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.caption.bold())
                    .accessibilityHidden(true)

                Text("Optimized")
                    .font(.caption.bold())
            }
            .foregroundStyle(.green)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.green.opacity(0.12))
            .clipShape(Capsule())
        }
    }

    private var isOptimized: Bool {
        ButtonAutomationWorkspace.production().automationExists(for: button)
    }
}
