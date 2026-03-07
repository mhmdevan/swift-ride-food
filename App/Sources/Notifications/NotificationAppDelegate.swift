import UIKit

final class NotificationAppDelegate: NSObject, UIApplicationDelegate {
    var pushNotificationCoordinator: PushNotificationCoordinator?

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        guard let pushNotificationCoordinator else {
            return
        }

        Task { @MainActor in
            await pushNotificationCoordinator.didRegisterForRemoteNotifications(deviceToken: deviceToken)
        }
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        guard let pushNotificationCoordinator else {
            return
        }

        Task { @MainActor in
            await pushNotificationCoordinator.didFailToRegisterForRemoteNotifications(error: error)
        }
    }

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        guard let pushNotificationCoordinator else {
            completionHandler(.noData)
            return
        }

        Task { @MainActor in
            let result = await pushNotificationCoordinator.didReceiveRemoteNotification(userInfo)
            completionHandler(result)
        }
    }
}
