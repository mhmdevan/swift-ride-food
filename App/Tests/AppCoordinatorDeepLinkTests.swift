import Analytics
@testable import SwiftRideFood
import XCTest

@MainActor
final class AppCoordinatorDeepLinkTests: XCTestCase {
    func testHandleIncomingURLRoutesImmediatelyWhenAuthenticated() throws {
        let coordinator = AppCoordinator()
        let offerID = "A0000000-0000-0000-0000-000000000010"
        let url = try XCTUnwrap(URL(string: "swiftridefood://offers/\(offerID)"))

        let result = coordinator.handleIncomingURL(url, isAuthenticated: true)

        XCTAssertEqual(result, .routed(offerID: try XCTUnwrap(UUID(uuidString: offerID))))
        XCTAssertEqual(
            coordinator.path,
            [
                .catalog,
                .offerDetail(id: try XCTUnwrap(UUID(uuidString: offerID)))
            ]
        )
    }

    func testHandleIncomingURLStoresPendingRouteWhenAuthenticationIsRequired() throws {
        let coordinator = AppCoordinator()
        let offerID = "A0000000-0000-0000-0000-000000000011"
        let url = try XCTUnwrap(URL(string: "https://app.swiftridefood.com/offers/\(offerID)"))

        let firstResult = coordinator.handleIncomingURL(url, isAuthenticated: false)
        let resumed = coordinator.consumePendingRouteAfterAuthenticationIfNeeded()

        XCTAssertEqual(
            firstResult,
            .requiresAuthentication(offerID: try XCTUnwrap(UUID(uuidString: offerID)))
        )
        XCTAssertTrue(resumed)
        XCTAssertEqual(
            coordinator.path,
            [
                .catalog,
                .offerDetail(id: try XCTUnwrap(UUID(uuidString: offerID)))
            ]
        )
    }

    func testHandleIncomingURLReturnsFailureForMalformedOfferRoute() throws {
        let coordinator = AppCoordinator()
        let url = try XCTUnwrap(URL(string: "swiftridefood://offers"))

        let result = coordinator.handleIncomingURL(url, isAuthenticated: true)

        XCTAssertEqual(result, .failed(.invalidPath))
        XCTAssertTrue(coordinator.path.isEmpty)
    }

    func testHandleIncomingURLReturnsNotHandledForUnrelatedURL() throws {
        let coordinator = AppCoordinator()
        let url = try XCTUnwrap(URL(string: "myapp://login?token=abc"))

        let result = coordinator.handleIncomingURL(url, isAuthenticated: false)

        XCTAssertEqual(result, .notHandled)
        XCTAssertFalse(coordinator.consumePendingRouteAfterAuthenticationIfNeeded())
    }

    func testHandleIncomingURLTracksIgnoredAndFailedTelemetry() async throws {
        let tracker = InMemoryAnalyticsTracker()
        let crashReporter = InMemoryCrashReporter()
        let dependencyContainer = AppDependencyContainer(
            analyticsTracker: tracker,
            crashReporter: crashReporter
        )
        let coordinator = AppCoordinator(dependencyContainer: dependencyContainer)

        let ignoredURL = try XCTUnwrap(URL(string: "myapp://login?token=abc"))
        let failedURL = try XCTUnwrap(URL(string: "swiftridefood://offers"))

        _ = coordinator.handleIncomingURL(ignoredURL, isAuthenticated: false)
        _ = coordinator.handleIncomingURL(failedURL, isAuthenticated: false)
        try? await Task.sleep(nanoseconds: 20_000_000)

        let trackedEvents = await tracker.trackedEvents()
        XCTAssertTrue(trackedEvents.contains(where: { $0.name == ObservabilityEventName.DeepLink.ignored }))
        XCTAssertTrue(trackedEvents.contains(where: { $0.name == ObservabilityEventName.DeepLink.failed }))
    }
}
