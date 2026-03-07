// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "FeaturesHome",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "FeaturesHome", targets: ["FeaturesHome"])
    ],
    dependencies: [
        .package(path: "../Core"),
        .package(path: "../DesignSystem"),
        .package(path: "../Analytics")
    ],
    targets: [
        .target(
            name: "FeaturesHome",
            dependencies: [
                .product(name: "Core", package: "Core"),
                .product(name: "DesignSystem", package: "DesignSystem"),
                .product(name: "Analytics", package: "Analytics")
            ]
        ),
        .testTarget(name: "FeaturesHomeTests", dependencies: ["FeaturesHome"])
    ]
)
