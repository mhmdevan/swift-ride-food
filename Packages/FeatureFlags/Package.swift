// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "FeatureFlags",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "FeatureFlags", targets: ["FeatureFlags"])
    ],
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "10.0.0")
    ],
    targets: [
        .target(
            name: "FeatureFlags",
            dependencies: [
                .product(
                    name: "FirebaseRemoteConfig",
                    package: "firebase-ios-sdk",
                    condition: .when(platforms: [.iOS])
                )
            ]
        ),
        .testTarget(name: "FeatureFlagsTests", dependencies: ["FeatureFlags"])
    ]
)
