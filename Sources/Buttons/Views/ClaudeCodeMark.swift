import SwiftUI

struct ClaudeCodeMark: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(.white)

            ForEach(0..<6) { index in
                Capsule()
                    .fill(Color(red: 0.62, green: 0.24, blue: 0.14))
                    .frame(width: 2.2, height: 9.6)
                    .offset(y: -0.4)
                    .rotationEffect(.degrees(Double(index) * 60))
            }

            Circle()
                .fill(.white)
                .frame(width: 4.6, height: 4.6)
        }
        .frame(width: 14, height: 14)
    }
}
