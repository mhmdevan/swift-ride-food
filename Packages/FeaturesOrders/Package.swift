// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "FeaturesOrders",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "FeaturesOrders", targets: ["FeaturesOrders"])
    ],
    dependencies: [
        .package(path: "../Core"),
        .package(path: "../Data"),
        .package(path: "../DesignSystem"),
        .package(path: "../Analytics")
    ],
    targets: [
        .target(
            name: "FeaturesOrders",
            dependencies: [
                .product(name: "Core", package: "Core"),
                .product(name: "Data", package: "Data"),
                .product(name: "DesignSystem", package: "DesignSystem"),
                .product(name: "Analytics", package: "Analytics")
            ]
        ),
        .testTarget(name: "FeaturesOrdersTests", dependencies: ["FeaturesOrders"])
    ]
)
