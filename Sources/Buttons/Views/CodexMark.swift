import SwiftUI

struct CodexMark: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .stroke(.white, lineWidth: 1.7)

            Path { path in
                path.move(to: CGPoint(x: 4, y: 4.5))
                path.addLine(to: CGPoint(x: 7.2, y: 7))
                path.addLine(to: CGPoint(x: 4, y: 9.5))
            }
            .stroke(.white, style: StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round))

            Path { path in
                path.move(to: CGPoint(x: 8.2, y: 9.5))
                path.addLine(to: CGPoint(x: 11, y: 9.5))
            }
            .stroke(.white, style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
        }
        .frame(width: 14, height: 14)
    }
}
