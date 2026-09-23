// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "macwindow",
    platforms: [.macOS(.v13)],
    targets: [
        .target(name: "MacWindowCore"),
        .executableTarget(name: "macwindow", dependencies: ["MacWindowCore"]),
        .testTarget(name: "MacWindowCoreTests", dependencies: ["MacWindowCore"]),
    ]
)
