import AppKit
import Foundation

let outputPath = CommandLine.arguments.dropFirst().first ?? "Buttons.icns"
let outputURL = URL(filePath: outputPath)
let fileManager = FileManager.default
let iconsetURL = fileManager.temporaryDirectory
    .appending(path: "Buttons-\(UUID().uuidString).iconset", directoryHint: .isDirectory)

try fileManager.createDirectory(at: iconsetURL, withIntermediateDirectories: true)
defer {
    try? fileManager.removeItem(at: iconsetURL)
}

let iconSizes: [(base: Int, scale: Int)] = [
    (16, 1),
    (16, 2),
    (32, 1),
    (32, 2),
    (128, 1),
    (128, 2),
    (256, 1),
    (256, 2),
    (512, 1),
    (512, 2),
]

for iconSize in iconSizes {
    let pixels = iconSize.base * iconSize.scale
    let image = renderIcon(pixels: pixels)
    let filename = iconSize.scale == 1
        ? "icon_\(iconSize.base)x\(iconSize.base).png"
        : "icon_\(iconSize.base)x\(iconSize.base)@2x.png"
    let url = iconsetURL.appending(path: filename)
    guard let tiffData = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiffData),
          let pngData = bitmap.representation(using: .png, properties: [:])
    else {
        throw IconRenderError.failedPNG(filename)
    }

    try pngData.write(to: url, options: .atomic)
}

try fileManager.createDirectory(at: outputURL.deletingLastPathComponent(), withIntermediateDirectories: true)
try? fileManager.removeItem(at: outputURL)

let iconutil = Process()
iconutil.executableURL = URL(filePath: "/usr/bin/iconutil")
iconutil.arguments = ["-c", "icns", iconsetURL.path, "-o", outputURL.path]
try iconutil.run()
iconutil.waitUntilExit()

guard iconutil.terminationStatus == 0 else {
    throw IconRenderError.iconutilFailed(iconutil.terminationStatus)
}

private func renderIcon(pixels: Int) -> NSImage {
    let size = NSSize(width: pixels, height: pixels)
    let image = NSImage(size: size)
    let scale = CGFloat(pixels) / 1024

    func rect(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat) -> NSRect {
        NSRect(x: x * scale, y: y * scale, width: width * scale, height: height * scale)
    }

    func radius(_ value: CGFloat) -> CGFloat {
        value * scale
    }

    image.lockFocus()
    NSGraphicsContext.current?.imageInterpolation = .high
    NSColor.clear.setFill()
    NSRect(origin: .zero, size: size).fill()

    let base = NSBezierPath(roundedRect: rect(70, 70, 884, 884), xRadius: radius(222), yRadius: radius(222))
    NSColor(calibratedRed: 0.94, green: 0.78, blue: 0.20, alpha: 1).setFill()
    base.fill()

    let topSheen = NSGradient(colors: [
        NSColor(calibratedRed: 1.0, green: 0.91, blue: 0.36, alpha: 1),
        NSColor(calibratedRed: 0.95, green: 0.75, blue: 0.10, alpha: 1),
    ])
    topSheen?.draw(in: base, angle: 90)

    NSColor(calibratedWhite: 1, alpha: 0.34).setStroke()
    base.lineWidth = max(2, 18 * scale)
    base.stroke()

    let innerShadow = NSBezierPath(roundedRect: rect(158, 158, 708, 708), xRadius: radius(170), yRadius: radius(170))
    NSColor(calibratedWhite: 0, alpha: 0.11).setFill()
    innerShadow.fill()

    let buttonFace = NSBezierPath(roundedRect: rect(192, 192, 640, 640), xRadius: radius(154), yRadius: radius(154))
    NSColor(calibratedRed: 1.0, green: 0.84, blue: 0.17, alpha: 1).setFill()
    buttonFace.fill()

    let faceSheen = NSGradient(colors: [
        NSColor(calibratedRed: 1.0, green: 0.92, blue: 0.34, alpha: 1),
        NSColor(calibratedRed: 0.91, green: 0.66, blue: 0.05, alpha: 1),
    ])
    faceSheen?.draw(in: buttonFace, angle: 90)

    NSColor(calibratedWhite: 1, alpha: 0.38).setStroke()
    buttonFace.lineWidth = max(2, 14 * scale)
    buttonFace.stroke()

    let glyph = NSBezierPath(roundedRect: rect(308, 332, 408, 360), xRadius: radius(82), yRadius: radius(82))
    NSColor(calibratedRed: 0.09, green: 0.09, blue: 0.10, alpha: 1).setFill()
    glyph.fill()

    NSColor(calibratedRed: 1.0, green: 0.83, blue: 0.20, alpha: 1).setFill()
    for row in 0..<2 {
        for column in 0..<3 {
            let x = 368 + CGFloat(column) * 88
            let y = 464 + CGFloat(row) * 82
            NSBezierPath(ovalIn: rect(x, y, 36, 36)).fill()
        }
    }

    let play = NSBezierPath()
    play.move(to: NSPoint(x: 572 * scale, y: 410 * scale))
    play.line(to: NSPoint(x: 572 * scale, y: 602 * scale))
    play.line(to: NSPoint(x: 698 * scale, y: 506 * scale))
    play.close()
    play.fill()

    image.unlockFocus()
    return image
}

private enum IconRenderError: Error, CustomStringConvertible {
    case failedPNG(String)
    case iconutilFailed(Int32)

    var description: String {
        switch self {
        case .failedPNG(let filename):
            "Could not render \(filename)."
        case .iconutilFailed(let code):
            "iconutil failed with exit code \(code)."
        }
    }
}
