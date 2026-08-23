// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "KXSFMidnightGlassCore",
    platforms: [
        .iOS(.v18),
        .macOS(.v14),
    ],
    products: [
        .library(name: "KXSFMidnightGlassCore", targets: ["KXSFMidnightGlassCore"]),
    ],
    targets: [
        .target(name: "KXSFMidnightGlassCore"),
        .testTarget(
            name: "KXSFMidnightGlassCoreTests",
            dependencies: ["KXSFMidnightGlassCore"]
        ),
    ]
)
