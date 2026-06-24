import ButtonsCore
import SwiftUI

@main
struct ButtonsApp: App {
    @State private var library = ButtonLibrary.production()

    var body: some Scene {
        WindowGroup {
            AppRootView(library: library)
                .frame(minWidth: 920, minHeight: 640)
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Button") {
                    NotificationCenter.default.post(name: .newButtonRequested, object: nil)
                }
                .keyboardShortcut("n")
            }
        }
    }
}

extension Notification.Name {
    static let newButtonRequested = Notification.Name("newButtonRequested")
}
