import SwiftUI

struct AppToolbarView: View {
    let newAction: () -> Void
    let importAction: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Text("Buttons")
                .font(.largeTitle)
                .bold()
                .foregroundStyle(.primary)

            Spacer()

            Button("Import", systemImage: "square.and.arrow.down", action: importAction)
                .buttonStyle(ChromePillButtonStyle(tint: .black.opacity(0.54)))

            Button("New", systemImage: "plus", action: newAction)
                .buttonStyle(ChromePillButtonStyle(tint: .black))
        }
        .padding(.horizontal, 28)
        .padding(.top, 24)
        .padding(.bottom, 18)
    }
}
