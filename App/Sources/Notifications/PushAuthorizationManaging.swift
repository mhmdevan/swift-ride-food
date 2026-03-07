import UIKit
import UserNotifications

@MainActor
protocol PushAuthorizationManaging {
    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool
    func registerForRemoteNotifications()
}

@MainActor
final class UserNotificationPushAuthorizationManager: PushAuthorizationManaging {
    private let notificationCenter: UNUserNotificationCenter
    private let application: UIApplication

    init(
        notificationCenter: UNUserNotificationCenter = .current(),
        application: UIApplication = .shared
    ) {
        self.notificationCenter = notificationCenter
        self.application = application
    }

    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool {
        try await notificationCenter.requestAuthorization(options: options)
    }

    func registerForRemoteNotifications() {
        application.registerForRemoteNotifications()
    }
}
