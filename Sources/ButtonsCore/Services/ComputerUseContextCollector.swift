import AppKit
import ApplicationServices
import Foundation
import ScreenCaptureKit

public struct ComputerUseContextSnapshot: Sendable {
    public var contextURL: URL
    public var summary: String
}

@MainActor
public final class ComputerUseContextCollector {
    public init() {}

    public func collect(
        for button: ActionButton,
        workspace: ButtonAutomationWorkspace
    ) async -> ComputerUseContextSnapshot {
        let computerUseURL = workspace.computerUseURL(for: button)
        let contextURL = workspace.computerUseContextURL(for: button)
        let accessibilityTreeURL = workspace.accessibilityTreeURL(for: button)
        var sections: [String] = []

        do {
            try FileManager.default.createDirectory(at: computerUseURL, withIntermediateDirectories: true)
            _ = try workspace.ensureWorkspace(for: button)
        } catch {
            let summary = "Computer use workspace could not be prepared: \(error.localizedDescription)"
            return ComputerUseContextSnapshot(contextURL: contextURL, summary: summary)
        }

        let screenPermission = screenRecordingPermissionSummary()
        sections.append(screenPermission)
        sections.append(await captureScreens(for: button, workspace: workspace))

        let accessibilityTree = accessibilityTreeSummary()
        try? accessibilityTree.write(to: accessibilityTreeURL, atomically: true, encoding: .utf8)
        sections.append("""
        ## Accessibility

        \(AXIsProcessTrusted() ? "Accessibility permission: granted." : "Accessibility permission: missing.")
        Accessibility tree: \(accessibilityTreeURL.path)
        """)

        let body = """
        # Computer Use Context

        Button: \(button.title)
        Captured: \(ISO8601DateFormatter().string(from: Date()))
        Tools: \(workspace.computerUseToolsURL(for: button).path)

        \(sections.joined(separator: "\n\n"))
        """

        try? body.write(to: contextURL, atomically: true, encoding: .utf8)

        return ComputerUseContextSnapshot(
            contextURL: contextURL,
            summary: """
            Computer use context: \(contextURL.path)
            Screen and accessibility data live in: \(computerUseURL.path)
            \(screenPermission.replacingOccurrences(of: "\n", with: " "))
            """
        )
    }

    private func screenRecordingPermissionSummary() -> String {
        if CGPreflightScreenCaptureAccess() {
            return """
            ## Screen Recording

            Screen Recording permission: granted.
            """
        }

        _ = CGRequestScreenCaptureAccess()
        return """
        ## Screen Recording

        Screen Recording permission: missing or not yet refreshed. Buttons requested it. Grant Screen Recording to Buttons in System Settings, then run the button again for live screenshots.
        """
    }

    private func captureScreens(
        for button: ActionButton,
        workspace: ButtonAutomationWorkspace
    ) async -> String {
        do {
            let captures = try await captureAllScreensAsJPEG()
            var lines = [
                "## Screens",
                "Captured \(captures.count) screen(s). Buttons windows are excluded when ScreenCaptureKit exposes them.",
            ]

            for (index, capture) in captures.enumerated() {
                let filename = "screen-\(index + 1).jpg"
                let url = workspace.computerUseURL(for: button).appending(path: filename)
                try capture.imageData.write(to: url, options: .atomic)
                lines.append("- \(capture.label): \(url.path)")
                lines.append("  AppKit frame: x=\(Int(capture.displayFrame.minX)) y=\(Int(capture.displayFrame.minY)) w=\(capture.displayWidthInPoints) h=\(capture.displayHeightInPoints)")
                lines.append("  Screenshot pixels: \(capture.screenshotWidthInPixels)x\(capture.screenshotHeightInPixels)")
            }

            return lines.joined(separator: "\n")
        } catch {
            return """
            ## Screens

            Screen capture failed: \(error.localizedDescription)
            """
        }
    }

    private func captureAllScreensAsJPEG() async throws -> [ComputerUseScreenCapture] {
        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
        guard !content.displays.isEmpty else {
            throw ComputerUseContextError.noDisplayAvailable
        }

        let mouseLocation = NSEvent.mouseLocation
        let excludedBundleIdentifiers = Set(
            [
                Bundle.main.bundleIdentifier,
                ProcessInfo.processInfo.environment["BUTTONS_HOST_BUNDLE_IDENTIFIER"],
            ]
                .compactMap { $0 }
                .filter { !$0.isEmpty }
        )
        let ownAppWindows = content.windows.filter { window in
            guard let bundleIdentifier = window.owningApplication?.bundleIdentifier else {
                return false
            }

            return excludedBundleIdentifiers.contains(bundleIdentifier)
        }
        let nsScreenByDisplayID = Self.screenLookupByDisplayID()

        let sortedDisplays = content.displays.sorted { displayA, displayB in
            let frameA = nsScreenByDisplayID[displayA.displayID]?.frame ?? displayA.frame
            let frameB = nsScreenByDisplayID[displayB.displayID]?.frame ?? displayB.frame
            let aContainsCursor = frameA.contains(mouseLocation)
            let bContainsCursor = frameB.contains(mouseLocation)
            if aContainsCursor != bContainsCursor {
                return aContainsCursor
            }
            return displayA.displayID < displayB.displayID
        }

        var captures: [ComputerUseScreenCapture] = []

        for (index, display) in sortedDisplays.enumerated() {
            let displayFrame = nsScreenByDisplayID[display.displayID]?.frame
                ?? CGRect(x: display.frame.origin.x, y: display.frame.origin.y, width: CGFloat(display.width), height: CGFloat(display.height))
            let isCursorScreen = displayFrame.contains(mouseLocation)
            let configuration = SCStreamConfiguration()
            let maxDimension = 1280
            let aspectRatio = CGFloat(display.width) / CGFloat(max(1, display.height))
            if display.width >= display.height {
                configuration.width = maxDimension
                configuration.height = Int(CGFloat(maxDimension) / aspectRatio)
            } else {
                configuration.height = maxDimension
                configuration.width = Int(CGFloat(maxDimension) * aspectRatio)
            }

            let filter = SCContentFilter(display: display, excludingWindows: ownAppWindows)
            let cgImage = try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: configuration)
            guard let imageData = NSBitmapImageRep(cgImage: cgImage)
                .representation(using: .jpeg, properties: [.compressionFactor: 0.82])
            else {
                continue
            }

            let label: String
            if sortedDisplays.count == 1 {
                label = "screen 1 — cursor is here"
            } else if isCursorScreen {
                label = "screen \(index + 1) of \(sortedDisplays.count) — cursor is here"
            } else {
                label = "screen \(index + 1) of \(sortedDisplays.count)"
            }

            captures.append(
                ComputerUseScreenCapture(
                    imageData: imageData,
                    label: label,
                    isCursorScreen: isCursorScreen,
                    displayWidthInPoints: Int(displayFrame.width),
                    displayHeightInPoints: Int(displayFrame.height),
                    displayFrame: displayFrame,
                    screenshotWidthInPixels: configuration.width,
                    screenshotHeightInPixels: configuration.height
                )
            )
        }

        guard !captures.isEmpty else {
            throw ComputerUseContextError.noScreenCaptureData
        }

        return captures
    }

    private static func screenLookupByDisplayID() -> [CGDirectDisplayID: NSScreen] {
        var screens: [CGDirectDisplayID: NSScreen] = [:]
        for screen in NSScreen.screens {
            if let screenNumber = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID {
                screens[screenNumber] = screen
            }
        }
        return screens
    }

    private func accessibilityTreeSummary() -> String {
        guard AXIsProcessTrusted() else {
            let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
            _ = AXIsProcessTrustedWithOptions(options)
            return """
            # Accessibility Tree

            Accessibility permission is missing. Buttons requested it. Grant Accessibility to Buttons in System Settings, then run the button again for live UI controls.
            """
        }

        let ownProcessIdentifier = ProcessInfo.processInfo.processIdentifier
        let apps = NSWorkspace.shared.runningApplications
            .filter { app in
                app.activationPolicy == .regular &&
                    app.processIdentifier != ownProcessIdentifier &&
                    app.localizedName?.isEmpty == false
            }
            .prefix(14)

        var lines = [
            "# Accessibility Tree",
            "",
            "Coordinates are macOS accessibility frames. Prefer named controls over coordinates.",
        ]

        for app in apps {
            let appElement = AXUIElementCreateApplication(app.processIdentifier)
            guard let windows = attribute(appElement, kAXWindowsAttribute) as? [AXUIElement], !windows.isEmpty else {
                continue
            }

            lines.append("")
            lines.append("## \(app.localizedName ?? app.bundleIdentifier ?? "App")")

            for (windowIndex, window) in windows.prefix(4).enumerated() {
                lines.append("- window \(windowIndex + 1): \(elementSummary(window))")
                appendChildren(of: window, to: &lines, depth: 1, remainingBudget: 80)
            }
        }

        return lines.joined(separator: "\n")
    }

    private func appendChildren(
        of element: AXUIElement,
        to lines: inout [String],
        depth: Int,
        remainingBudget: Int
    ) {
        guard depth <= 4, remainingBudget > 0 else { return }
        guard let children = attribute(element, kAXChildrenAttribute) as? [AXUIElement], !children.isEmpty else {
            return
        }

        var budget = remainingBudget
        for child in children.prefix(28) {
            guard budget > 0 else { return }
            let summary = elementSummary(child)
            if !summary.isEmpty {
                lines.append("\(String(repeating: "  ", count: depth))- \(summary)")
                budget -= 1
            }
            appendChildren(of: child, to: &lines, depth: depth + 1, remainingBudget: min(18, budget))
        }
    }

    private func elementSummary(_ element: AXUIElement) -> String {
        let role = stringAttribute(element, kAXRoleAttribute) ?? "AXUnknown"
        let title = stringAttribute(element, kAXTitleAttribute)
        let description = stringAttribute(element, kAXDescriptionAttribute)
        let value = stringAttribute(element, kAXValueAttribute)
        let identifier = stringAttribute(element, kAXIdentifierAttribute)
        let frame = frameSummary(element)

        let text = [
            title.map { "title=\"\($0)\"" },
            description.map { "description=\"\($0)\"" },
            value.map { "value=\"\($0)\"" },
            identifier.map { "id=\"\($0)\"" },
            frame,
        ]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        return "\(role) \(text)".trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func frameSummary(_ element: AXUIElement) -> String? {
        guard let positionObject = attribute(element, kAXPositionAttribute),
              let sizeObject = attribute(element, kAXSizeAttribute)
        else {
            return nil
        }

        guard CFGetTypeID(positionObject) == AXValueGetTypeID(),
              CFGetTypeID(sizeObject) == AXValueGetTypeID()
        else {
            return nil
        }

        let positionValue = positionObject as! AXValue
        let sizeValue = sizeObject as! AXValue

        var position = CGPoint.zero
        var size = CGSize.zero
        guard AXValueGetValue(positionValue, .cgPoint, &position),
              AXValueGetValue(sizeValue, .cgSize, &size)
        else {
            return nil
        }

        guard size.width > 0, size.height > 0 else {
            return nil
        }

        return "frame={x:\(Int(position.x)), y:\(Int(position.y)), w:\(Int(size.width)), h:\(Int(size.height))}"
    }

    private func stringAttribute(_ element: AXUIElement, _ attributeName: String) -> String? {
        guard let value = attribute(element, attributeName) else {
            return nil
        }

        let raw: String?
        if let string = value as? String {
            raw = string
        } else if let number = value as? NSNumber {
            raw = number.stringValue
        } else {
            raw = nil
        }

        let trimmed = raw?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? nil : String(trimmed.prefix(140))
    }

    private func attribute(_ element: AXUIElement, _ attributeName: String) -> AnyObject? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attributeName as CFString, &value) == .success else {
            return nil
        }
        return value
    }
}

private struct ComputerUseScreenCapture {
    var imageData: Data
    var label: String
    var isCursorScreen: Bool
    var displayWidthInPoints: Int
    var displayHeightInPoints: Int
    var displayFrame: CGRect
    var screenshotWidthInPixels: Int
    var screenshotHeightInPixels: Int
}

private enum ComputerUseContextError: LocalizedError {
    case noDisplayAvailable
    case noScreenCaptureData

    var errorDescription: String? {
        switch self {
        case .noDisplayAvailable:
            "No display is available for capture."
        case .noScreenCaptureData:
            "ScreenCaptureKit did not return image data."
        }
    }
}
