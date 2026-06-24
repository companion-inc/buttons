import SwiftUI

struct AppBackgroundView: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.96, green: 0.95, blue: 0.92),
                Color(red: 0.90, green: 0.92, blue: 0.96),
                Color(red: 0.93, green: 0.90, blue: 0.87),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}
