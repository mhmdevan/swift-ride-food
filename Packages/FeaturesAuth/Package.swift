// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "FeaturesAuth",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "FeaturesAuth", targets: ["FeaturesAuth"])
    ],
    dependencies: [
        .package(path: "../Core"),
        .package(path: "../DesignSystem"),
        .package(path: "../Analytics"),
        .package(path: "../Data")
    ],
    targets: [
        .target(
            name: "FeaturesAuth",
            dependencies: [
                .product(name: "Core", package: "Core"),
                .product(name: "DesignSystem", package: "DesignSystem"),
                .product(name: "Analytics", package: "Analytics"),
                .product(name: "Data", package: "Data")
            ]
        ),
        .testTarget(name: "FeaturesAuthTests", dependencies: ["FeaturesAuth"])
    ]
)
