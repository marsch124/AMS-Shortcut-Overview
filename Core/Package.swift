// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "ShortcutCore",
    platforms: [.macOS(.v14)],
    products: [.library(name: "ShortcutCore", targets: ["ShortcutCore"])],
    targets: [
        .target(name: "ShortcutCore"),
        .testTarget(name: "ShortcutCoreTests", dependencies: ["ShortcutCore"]),
    ]
)
