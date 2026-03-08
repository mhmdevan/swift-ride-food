// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "FeaturesCatalogUIKit",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "FeaturesCatalogUIKit", targets: ["FeaturesCatalogUIKit"])
    ],
    dependencies: [
        .package(url: "https://github.com/apollographql/apollo-ios.git", from: "1.10.0")
    ],
    targets: [
        .target(
            name: "FeaturesCatalogUIKit",
            dependencies: [
                .product(
                    name: "Apollo",
                    package: "apollo-ios",
                    condition: .when(platforms: [.iOS, .macOS])
                )
            ]
        ),
        .testTarget(name: "FeaturesCatalogUIKitTests", dependencies: ["FeaturesCatalogUIKit"])
    ]
)
