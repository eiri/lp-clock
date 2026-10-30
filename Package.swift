// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "LPClock",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(name: "LPClock"),
        .testTarget(name: "LPClockTests", dependencies: ["LPClock"]),
    ]
)
