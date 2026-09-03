// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "TiboResetSignal",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "TiboResetSignal", targets: ["TiboResetSignal"])
    ],
    targets: [
        .executableTarget(name: "TiboResetSignal"),
        .testTarget(
            name: "TiboResetSignalTests",
            dependencies: ["TiboResetSignal"]
        )
    ],
    swiftLanguageModes: [.v5]
)
