// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Analytics",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "Analytics", targets: ["Analytics"])
    ],
    dependencies: [
        .package(path: "../Core"),
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "10.0.0")
    ],
    targets: [
        .target(
            name: "Analytics",
            dependencies: [
                .product(name: "Core", package: "Core"),
                .product(
                    name: "FirebaseAnalytics",
                    package: "firebase-ios-sdk",
                    condition: .when(platforms: [.iOS])
                ),
                .product(
                    name: "FirebaseCrashlytics",
                    package: "firebase-ios-sdk",
                    condition: .when(platforms: [.iOS])
                )
            ]
        ),
        .testTarget(name: "AnalyticsTests", dependencies: ["Analytics"])
    ]
)
