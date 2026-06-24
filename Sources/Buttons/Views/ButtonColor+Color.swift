import ButtonsCore
import SwiftUI

extension ButtonColor {
    var swiftUIColor: Color {
        Color(hex: hex)
    }

    var swiftUIForegroundColor: Color {
        Color(hex: foregroundHex)
    }
}
