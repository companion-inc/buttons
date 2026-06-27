import ButtonsCore
import SwiftUI

struct PhysicalButtonTileStyle: ButtonStyle {
    let face: ButtonFace

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .physicalButtonSurface(face: face, isPressed: configuration.isPressed)
    }
}
