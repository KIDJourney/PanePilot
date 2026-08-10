// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "PanePilot",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "PanePilot", targets: ["PanePilot"]),
        .library(name: "PanePilotCore", targets: ["PanePilotCore"])
    ],
    targets: [
        .target(
            name: "PanePilotCore"
        ),
        .executableTarget(
            name: "PanePilot",
            dependencies: ["PanePilotCore"]
        ),
        .testTarget(
            name: "PanePilotCoreTests",
            dependencies: ["PanePilotCore"]
        )
    ]
)
