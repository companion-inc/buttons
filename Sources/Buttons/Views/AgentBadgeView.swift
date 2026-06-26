import ButtonsCore
import SwiftUI

struct AgentBadgeView: View {
    let provider: AIProvider

    var body: some View {
        HStack(spacing: 6) {
            AgentMarkView(provider: provider)
                .frame(width: 14, height: 14)

            Text(provider.shortTitle)
                .font(.caption.bold())
                .lineLimit(1)
        }
        .fixedSize(horizontal: true, vertical: false)
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            LinearGradient(
                colors: badgeColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .strokeBorder(.white.opacity(0.24), lineWidth: 1)
        )
        .fixedSize(horizontal: true, vertical: false)
    }

    private var badgeColors: [Color] {
        switch provider {
        case .codex:
            [Color.black.opacity(0.86), Color.black.opacity(0.64)]
        case .claudeCode:
            [Color(red: 0.77, green: 0.34, blue: 0.19), Color(red: 0.56, green: 0.22, blue: 0.13)]
        }
    }
}
