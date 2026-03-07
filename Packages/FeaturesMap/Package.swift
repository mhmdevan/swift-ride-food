// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "FeaturesMap",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "FeaturesMap", targets: ["FeaturesMap"])
    ],
    dependencies: [
        .package(path: "../Core"),
        .package(path: "../Data"),
        .package(path: "../DesignSystem"),
        .package(path: "../Analytics"),
        .package(path: "../Networking")
    ],
    targets: [
        .target(
            name: "FeaturesMap",
            dependencies: [
                .product(name: "Core", package: "Core"),
                .product(name: "Data", package: "Data"),
                .product(name: "DesignSystem", package: "DesignSystem"),
                .product(name: "Analytics", package: "Analytics"),
                .product(name: "Networking", package: "Networking")
            ]
        ),
        .testTarget(name: "FeaturesMapTests", dependencies: ["FeaturesMap"])
    ]
)
