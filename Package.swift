// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Buttons",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "Buttons", targets: ["Buttons"]),
        .executable(name: "ButtonsComputerUseRuntime", targets: ["ButtonsComputerUseRuntime"]),
        .library(name: "ButtonsCore", targets: ["ButtonsCore"]),
    ],
    targets: [
        .target(name: "ButtonsCore"),
        .executableTarget(
            name: "Buttons",
            dependencies: ["ButtonsCore"]
        ),
        .executableTarget(
            name: "ButtonsComputerUseRuntime",
            dependencies: ["ButtonsCore"]
        ),
        .testTarget(
            name: "ButtonsCoreTests",
            dependencies: ["ButtonsCore"]
        ),
    ]
)
