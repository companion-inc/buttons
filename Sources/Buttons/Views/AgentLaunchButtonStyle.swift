import SwiftUI

struct AgentLaunchButtonStyle: ButtonStyle {
    let color: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 11)
            .background(
                LinearGradient(
                    colors: [
                        color.opacity(0.95),
                        color.opacity(0.78),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(.white.opacity(0.38), lineWidth: 1)
            )
            .shadow(color: color.opacity(configuration.isPressed ? 0.12 : 0.28), radius: configuration.isPressed ? 4 : 12, y: configuration.isPressed ? 2 : 7)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.snappy(duration: 0.15), value: configuration.isPressed)
    }
}
