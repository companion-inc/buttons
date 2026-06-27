import ButtonsCore
import SwiftUI

struct PhysicalButtonSurfaceModifier: ViewModifier {
    let face: ButtonFace
    let isPressed: Bool

    func body(content: Content) -> some View {
        content
            .foregroundStyle(face.color.swiftUIForegroundColor)
            .background(background)
            .clipShape(shape)
            .overlay(topHighlight)
            .overlay(bottomShade)
            .overlay(edgeStroke)
            .shadow(
                color: shadowColor.opacity(isPressed ? 0.16 : 0.28),
                radius: isPressed ? 8 : 18,
                y: isPressed ? 5 : 14
            )
            .scaleEffect(isPressed ? 0.982 : 1)
            .offset(y: isPressed ? 4 : 0)
            .animation(.snappy(duration: 0.16), value: isPressed)
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: cornerRadius)
    }

    private var background: some ShapeStyle {
        switch face.surface {
        case .raised:
            AnyShapeStyle(
                LinearGradient(
                    colors: [
                        face.color.swiftUIColor.opacity(1),
                        face.color.swiftUIColor.opacity(0.90),
                        face.color.swiftUIColor.opacity(0.76),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        case .rubber:
            AnyShapeStyle(
                LinearGradient(
                    colors: [
                        face.color.swiftUIColor.opacity(0.96),
                        face.color.swiftUIColor.opacity(0.78),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        case .metal:
            AnyShapeStyle(
                LinearGradient(
                    colors: [
                        face.color.swiftUIColor.opacity(0.92),
                        Color.white.opacity(0.24),
                        face.color.swiftUIColor.opacity(0.74),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        case .glass:
            AnyShapeStyle(
                LinearGradient(
                    colors: [
                        face.color.swiftUIColor.opacity(0.80),
                        Color.white.opacity(0.20),
                        face.color.swiftUIColor.opacity(0.62),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        case .terminal:
            AnyShapeStyle(
                LinearGradient(
                    colors: [Color.black, face.color.swiftUIColor.opacity(0.82)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
    }

    private var topHighlight: some View {
        shape
            .strokeBorder(.white.opacity(face.color == .paper || face.color == .lemon ? 0.44 : 0.30), lineWidth: 3)
            .padding(2)
            .blendMode(.screen)
    }

    private var bottomShade: some View {
        shape
            .strokeBorder(.black.opacity(0.22), lineWidth: 5)
            .padding(.top, 5)
            .padding(2)
            .blendMode(.multiply)
    }

    private var edgeStroke: some View {
        shape
            .strokeBorder(.black.opacity(face.color == .paper || face.color == .lemon ? 0.10 : 0.16), lineWidth: 1)
    }

    private var shadowColor: Color {
        switch face.surface {
        case .terminal:
            Color.black
        case .glass, .raised, .rubber, .metal:
            face.color.swiftUIColor
        }
    }

    private var cornerRadius: CGFloat {
        switch face.surface {
        case .rubber:
            42
        case .terminal:
            30
        case .raised, .metal, .glass:
            38
        }
    }
}

extension View {
    func physicalButtonSurface(face: ButtonFace, isPressed: Bool = false) -> some View {
        modifier(PhysicalButtonSurfaceModifier(face: face, isPressed: isPressed))
    }
}
