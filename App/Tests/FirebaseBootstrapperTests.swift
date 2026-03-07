@testable import SwiftRideFood
import XCTest

final class FirebaseBootstrapperTests: XCTestCase {
    func testConfigureIfNeededReturnsFalseWhenConfigurationFileMissing() {
        var didConfigure = false

        let result = FirebaseBootstrapper.configureIfNeeded(
            hasConfigurationFile: { false },
            isAlreadyConfigured: { false },
            configure: { didConfigure = true }
        )

        XCTAssertFalse(result)
        XCTAssertFalse(didConfigure)
    }

    func testConfigureIfNeededIsIdempotentWhenAlreadyConfiguredAfterFirstCall() {
        var isConfigured = false
        var configureCallCount = 0

        let first = FirebaseBootstrapper.configureIfNeeded(
            hasConfigurationFile: { true },
            isAlreadyConfigured: { isConfigured },
            configure: {
                configureCallCount += 1
                isConfigured = true
            }
        )

        let second = FirebaseBootstrapper.configureIfNeeded(
            hasConfigurationFile: { true },
            isAlreadyConfigured: { isConfigured },
            configure: {
                configureCallCount += 1
                isConfigured = true
            }
        )

        XCTAssertTrue(first)
        XCTAssertTrue(second)
        XCTAssertEqual(configureCallCount, 1)
    }
}
