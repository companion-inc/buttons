import ApplicationServices
import ButtonsCore
import CoreGraphics
import Darwin
import Foundation

@main
@MainActor
enum ButtonsComputerUseRuntime {
    static func main() async {
        let arguments = Array(CommandLine.arguments.dropFirst())

        guard let command = arguments.first else {
            printUsage()
            Darwin.exit(2)
        }

        switch command {
        case "snapshot":
            await snapshot(arguments: Array(arguments.dropFirst()))

        case "permissions":
            printPermissions()

        case "help", "--help", "-h":
            printUsage()

        default:
            fputs("Unknown command: \(command)\n", stderr)
            printUsage()
            Darwin.exit(2)
        }
    }

    private static func snapshot(arguments: [String]) async {
        let options = parseOptions(arguments)

        guard let root = options["root"], !root.isEmpty else {
            fputs("Missing required --root path.\n", stderr)
            Darwin.exit(2)
        }

        let slug = options["slug"]?.trimmingCharacters(in: .whitespacesAndNewlines)
        let title = options["title"]?.trimmingCharacters(in: .whitespacesAndNewlines)
        let category = options["category"]?.trimmingCharacters(in: .whitespacesAndNewlines)

        let button = ActionButton(
            slug: slug?.isEmpty == false ? slug : "button",
            title: title?.isEmpty == false ? title! : "Button",
            subtitle: "Computer use",
            category: category?.isEmpty == false ? category! : "General",
            taskDescription: "Refresh computer-use context for this button.",
            face: ButtonFace(),
            workflow: ButtonWorkflow(steps: [])
        )

        let workspace = ButtonAutomationWorkspace(rootURL: URL(filePath: root, directoryHint: .isDirectory))
        let snapshot = await ComputerUseContextCollector().collect(for: button, workspace: workspace)

        print(snapshot.summary)
    }

    private static func printPermissions() {
        print(
            """
            screenRecording=\(CGPreflightScreenCaptureAccess())
            accessibility=\(AXIsProcessTrusted())
            """
        )
    }

    private static func parseOptions(_ arguments: [String]) -> [String: String] {
        var options: [String: String] = [:]
        var index = 0

        while index < arguments.count {
            let key = arguments[index]
            guard key.hasPrefix("--") else {
                index += 1
                continue
            }

            let name = String(key.dropFirst(2))
            let valueIndex = index + 1
            guard valueIndex < arguments.count else {
                options[name] = ""
                index += 1
                continue
            }

            options[name] = arguments[valueIndex]
            index += 2
        }

        return options
    }

    private static func printUsage() {
        print(
            """
            ButtonsComputerUseRuntime

            Commands:
              snapshot --root <buttons-root> --slug <button-slug> --title <button-title> [--category <category>]
              permissions
            """
        )
    }
}
