import Analytics
import Core
import Foundation
import PushNotifications
import UIKit
import UserNotifications

@MainActor
final class PushNotificationCoordinator {
    private let authorizationManager: any PushAuthorizationManaging
    private let pushService: PushNotificationService
    private let tracker: any AnalyticsTracking
    private let crashReporter: any CrashReporting
    private let globalErrorHandler: any GlobalErrorHandling

    private var hasPrepared = false
    private var hasRequestedAuthorization = false

    init(
        authorizationManager: any PushAuthorizationManaging = UserNotificationPushAuthorizationManager(),
        pushService: PushNotificationService,
        tracker: any AnalyticsTracking = NoOpAnalyticsTracker(),
        crashReporter: any CrashReporting = NoOpCrashReporter(),
        globalErrorHandler: any GlobalErrorHandling = NoOpGlobalErrorHandler()
    ) {
        self.authorizationManager = authorizationManager
        self.pushService = pushService
        self.tracker = tracker
        self.crashReporter = crashReporter
        self.globalErrorHandler = globalErrorHandler
    }

    func prepareIfNeeded() async {
        guard hasPrepared == false else {
            return
        }

        hasPrepared = true
        await pushService.configure()
        await tracker.track(AnalyticsEvent(name: "push_service_prepared"))
    }

    func requestAuthorizationIfNeeded() async {
        guard hasRequestedAuthorization == false else {
            return
        }

        hasRequestedAuthorization = true

        do {
            let granted = try await authorizationManager.requestAuthorization(options: [.alert, .badge, .sound])

            if granted {
                authorizationManager.registerForRemoteNotifications()
                await tracker.track(AnalyticsEvent(name: "push_authorization_granted"))
            } else {
                await tracker.track(AnalyticsEvent(name: "push_authorization_denied"))
            }
        } catch {
            await tracker.track(AnalyticsEvent(name: "push_authorization_failed"))
            await crashReporter.recordNonFatal(
                error,
                context: ["feature": "push", "action": "request_authorization"]
            )
            globalErrorHandler.present(
                .network(message: "Unable to request push notification permission."),
                source: "push_request_authorization"
            )
        }
    }

    func didRegisterForRemoteNotifications(deviceToken: Data) async {
        await pushService.didRegisterAPNSToken(deviceToken)

        let tokenPrefix = await pushService.currentFCMToken().map { String($0.prefix(8)) } ?? "none"
        await tracker.track(
            AnalyticsEvent(
                name: "push_token_registered",
                parameters: ["fcm_token_prefix": tokenPrefix]
            )
        )
    }

    func didFailToRegisterForRemoteNotifications(error: Error) async {
        await tracker.track(AnalyticsEvent(name: "push_registration_failed"))
        await crashReporter.recordNonFatal(
            error,
            context: ["feature": "push", "action": "register_apns_token"]
        )
    }

    func didReceiveRemoteNotification(_ userInfo: [AnyHashable: Any]) async -> UIBackgroundFetchResult {
        let result = await pushService.handleRemoteNotification(userInfo: userInfo)

        switch result {
        case .newData:
            await tracker.track(AnalyticsEvent(name: "push_remote_notification_new_data"))
            return .newData
        case .noData:
            return .noData
        case .failed:
            await tracker.track(AnalyticsEvent(name: "push_remote_notification_failed"))
            await crashReporter.addBreadcrumb(
                CrashBreadcrumb(
                    message: "Remote notification processing failed",
                    category: "push"
                )
            )
            return .failed
        }
    }
}
