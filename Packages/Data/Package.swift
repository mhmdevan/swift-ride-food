// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Data",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "Data", targets: ["Data"])
    ],
    dependencies: [
        .package(path: "../Core"),
        .package(path: "../Networking")
    ],
    targets: [
        .target(
            name: "Data",
            dependencies: [
                .product(name: "Core", package: "Core"),
                .product(name: "Networking", package: "Networking")
            ]
        ),
        .testTarget(
            name: "DataTests",
            dependencies: ["Data"]
        )
    ]
)
