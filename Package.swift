// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SLUJ",
    platforms: [.macOS(.v14)],
    targets: [
        .target(name: "SLUJCore"),
        .executableTarget(name: "SLUJ", dependencies: ["SLUJCore"]),
        .testTarget(name: "SLUJCoreTests", dependencies: ["SLUJCore"]),
    ]
)
