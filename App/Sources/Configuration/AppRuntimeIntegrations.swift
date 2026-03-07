import Analytics
import FeatureFlags
import PushNotifications

struct AppRuntimeIntegrations {
    enum Mode: Equatable {
        case firebase
        case fallback
    }

    struct Resolved {
        let mode: Mode
        let analyticsTracker: any AnalyticsTracking
        let crashReporter: any CrashReporting
        let rumMonitor: any RUMMonitoring
        let remoteConfigProvider: any RemoteConfigProviding
        let pushMessagingClient: any PushMessagingClient
    }

    static func resolve(firebaseConfigurationOverride: Bool? = nil) -> Resolved {
        let rumMonitor = makeRUMMonitor()
        _ = rumMonitor.configureIfNeeded(SentryBootstrapper.configuration())

        let isFirebaseConfigured = firebaseConfigurationOverride ?? FirebaseBootstrapper.configureIfNeeded()

        guard isFirebaseConfigured,
              let analyticsTracker = makeFirebaseAnalyticsTracker(),
              let crashReporter = makeFirebaseCrashReporter(),
              let remoteConfigProvider = makeFirebaseRemoteConfigProvider(),
              let pushMessagingClient = makeFirebasePushMessagingClient() else {
            return Resolved(
                mode: .fallback,
                analyticsTracker: NoOpAnalyticsTracker(),
                crashReporter: NoOpCrashReporter(),
                rumMonitor: rumMonitor,
                remoteConfigProvider: MockRemoteConfigProvider(),
                pushMessagingClient: MockPushMessagingClient()
            )
        }

        return Resolved(
            mode: .firebase,
            analyticsTracker: analyticsTracker,
            crashReporter: crashReporter,
            rumMonitor: rumMonitor,
            remoteConfigProvider: remoteConfigProvider,
            pushMessagingClient: pushMessagingClient
        )
    }

    private static func makeFirebaseAnalyticsTracker() -> (any AnalyticsTracking)? {
#if canImport(FirebaseAnalytics)
        return FirebaseAnalyticsTracker()
#else
        return nil
#endif
    }

    private static func makeFirebaseCrashReporter() -> (any CrashReporting)? {
#if canImport(FirebaseCrashlytics)
        return FirebaseCrashReporter()
#else
        return nil
#endif
    }

    private static func makeFirebaseRemoteConfigProvider() -> (any RemoteConfigProviding)? {
#if canImport(FirebaseRemoteConfig)
        return FirebaseRemoteConfigProvider()
#else
        return nil
#endif
    }

    private static func makeFirebasePushMessagingClient() -> (any PushMessagingClient)? {
#if canImport(FirebaseMessaging)
        return FirebaseMessagingClient()
#else
        return nil
#endif
    }

    private static func makeRUMMonitor() -> any RUMMonitoring {
#if canImport(Sentry)
        return SentryRUMMonitor()
#else
        return RUMMonitorFactory.makeDefault()
#endif
    }
}
