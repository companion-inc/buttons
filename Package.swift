// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Buttons",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "Buttons", targets: ["Buttons"]),
        .library(name: "ButtonsCore", targets: ["ButtonsCore"]),
    ],
    targets: [
        .target(name: "ButtonsCore"),
        .executableTarget(
            name: "Buttons",
            dependencies: ["ButtonsCore"]
        ),
        .testTarget(
            name: "ButtonsCoreTests",
            dependencies: ["ButtonsCore"]
        ),
    ]
)
