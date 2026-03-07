import BackgroundTasks
import SwiftUI

@main
struct SwiftRideFoodApp: App {
    @UIApplicationDelegateAdaptor(NotificationAppDelegate.self) private var notificationAppDelegate
    private let dependencyContainer = AppDependencyContainer()

    var body: some Scene {
        WindowGroup {
            RootView(dependencyContainer: dependencyContainer)
                .task {
                    notificationAppDelegate.pushNotificationCoordinator =
                        dependencyContainer.makePushNotificationCoordinator()
                    _ = await dependencyContainer
                        .makeOffersBackgroundRefreshManager()
                        .scheduleNextRefresh(after: nil)
                }
        }
        .backgroundTask(.appRefresh(OffersBackgroundRefreshManager.taskIdentifier)) {
            let outcome = await dependencyContainer.refreshOffersFeedInBackgroundTask()
            _ = await dependencyContainer
                .makeOffersBackgroundRefreshManager()
                .scheduleNextRefresh(after: outcome)
        }
    }
}
