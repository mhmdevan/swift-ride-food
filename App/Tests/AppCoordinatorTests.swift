import FeaturesHome
@testable import SwiftRideFood
import XCTest

@MainActor
final class AppCoordinatorTests: XCTestCase {
    func testHandleHomeActionPushesMapRoute() {
        let coordinator = AppCoordinator()

        coordinator.handleHomeAction(.map)

        XCTAssertEqual(coordinator.path, [.map])
    }

    func testHandleHomeActionPushesOrdersRoute() {
        let coordinator = AppCoordinator()

        coordinator.handleHomeAction(.orders)

        XCTAssertEqual(coordinator.path, [.orders])
    }

    func testHandleHomeActionPushesCatalogRoute() {
        let coordinator = AppCoordinator()

        coordinator.handleHomeAction(.catalog)

        XCTAssertEqual(coordinator.path, [.catalog])
    }

    func testHandleHomeActionPushesAuthRoute() {
        let coordinator = AppCoordinator()

        coordinator.handleHomeAction(.auth)

        XCTAssertEqual(coordinator.path, [.auth])
    }

    func testResetNavigationClearsPath() {
        let coordinator = AppCoordinator()
        coordinator.handleHomeAction(.map)
        coordinator.handleHomeAction(.orders)

        coordinator.resetNavigation()

        XCTAssertTrue(coordinator.path.isEmpty)
    }
}
