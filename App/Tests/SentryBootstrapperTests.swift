import Analytics
@testable import SwiftRideFood
import XCTest

final class SentryBootstrapperTests: XCTestCase {
    func testConfigurationReturnsNilWhenDSNMissing() {
        let configuration = SentryBootstrapper.configuration(valueProvider: { _ in nil })

        XCTAssertNil(configuration)
    }

    func testConfigurationDefaultsEnvironmentToProduction() {
        let values: [String: Any] = [
            "SENTRY_DSN": "https://example@sentry.io/1",
            "CFBundleShortVersionString": "1.2.3"
        ]
        let configuration = SentryBootstrapper.configuration(valueProvider: { values[$0] })

        XCTAssertEqual(configuration?.dsn, "https://example@sentry.io/1")
        XCTAssertEqual(configuration?.environment, "production")
        XCTAssertEqual(configuration?.release, "1.2.3")
    }

    func testConfigurationUsesProvidedEnvironmentWhenAvailable() {
        let values: [String: Any] = [
            "SENTRY_DSN": "https://example@sentry.io/1",
            "SENTRY_ENVIRONMENT": "staging",
            "CFBundleShortVersionString": "2.0.0"
        ]
        let configuration = SentryBootstrapper.configuration(valueProvider: { values[$0] })

        XCTAssertEqual(configuration?.environment, "staging")
        XCTAssertEqual(configuration?.release, "2.0.0")
    }
}
