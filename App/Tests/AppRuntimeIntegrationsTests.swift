import Analytics
import FeatureFlags
import PushNotifications
@testable import SwiftRideFood
import XCTest

final class AppRuntimeIntegrationsTests: XCTestCase {
    func testResolveUsesFallbackWhenFirebaseConfigurationFails() {
        let resolved = AppRuntimeIntegrations.resolve(firebaseConfigurationOverride: false)

        XCTAssertEqual(resolved.mode, .fallback)
        XCTAssertTrue(resolved.analyticsTracker is NoOpAnalyticsTracker)
        XCTAssertTrue(resolved.crashReporter is NoOpCrashReporter)
        XCTAssertNotNil(resolved.rumMonitor as Any)
        XCTAssertTrue(resolved.remoteConfigProvider is MockRemoteConfigProvider)
        XCTAssertTrue(resolved.pushMessagingClient is MockPushMessagingClient)
    }

    func testResolveUsesFirebaseModeWhenConfiguredAndProvidersAvailable() {
        let resolved = AppRuntimeIntegrations.resolve(firebaseConfigurationOverride: true)

#if canImport(FirebaseAnalytics) && canImport(FirebaseCrashlytics) && canImport(FirebaseRemoteConfig) && canImport(FirebaseMessaging)
        XCTAssertEqual(resolved.mode, .firebase)
        XCTAssertTrue(resolved.analyticsTracker is FirebaseAnalyticsTracker)
        XCTAssertTrue(resolved.crashReporter is FirebaseCrashReporter)
        XCTAssertNotNil(resolved.rumMonitor as Any)
        XCTAssertTrue(resolved.remoteConfigProvider is FirebaseRemoteConfigProvider)
        XCTAssertTrue(resolved.pushMessagingClient is FirebaseMessagingClient)
#else
        XCTAssertEqual(resolved.mode, .fallback)
#endif
    }
}
