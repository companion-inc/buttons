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
                .buttonStyle(.bordered)

            Button("New", systemImage: "plus", action: newAction)
                .buttonStyle(.borderedProminent)
        }
        .padding(.horizontal, 28)
        .padding(.top, 24)
        .padding(.bottom, 18)
    }
}
