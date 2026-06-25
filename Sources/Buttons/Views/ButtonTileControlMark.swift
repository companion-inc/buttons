import ButtonsCore
import SwiftUI

struct ButtonTileControlMark: View {
    let systemName: String
    let face: ButtonFace
    var size: CGFloat = 44
    var font: Font = .headline

    var body: some View {
        Image(systemName: systemName)
            .font(font.bold())
            .foregroundStyle(face.color.swiftUIForegroundColor)
            .frame(width: size, height: size)
            .background(.white.opacity(face.color == .paper || face.color == .lemon ? 0.36 : 0.24))
            .clipShape(Circle())
            .overlay(
                Circle()
                    .strokeBorder(.white.opacity(0.24), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.10), radius: 8, y: 4)
            .accessibilityHidden(true)
    }
}
