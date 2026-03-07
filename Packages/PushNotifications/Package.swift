// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "PushNotifications",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "PushNotifications", targets: ["PushNotifications"])
    ],
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "10.0.0")
    ],
    targets: [
        .target(
            name: "PushNotifications",
            dependencies: [
                .product(
                    name: "FirebaseMessaging",
                    package: "firebase-ios-sdk",
                    condition: .when(platforms: [.iOS])
                )
            ]
        ),
        .testTarget(name: "PushNotificationsTests", dependencies: ["PushNotifications"])
    ]
)
