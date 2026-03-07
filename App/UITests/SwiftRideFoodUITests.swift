import XCTest

final class SwiftRideFoodUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    func testLoginCreateOrderAndSeeHistory() {
        ensureAuthenticated()

        let ordersAction = app.buttons["home_action_orders"]
        XCTAssertTrue(ordersAction.waitForExistence(timeout: 6))
        ordersAction.tap()

        let titleInput = app.textFields["create_order_title_input"]
        XCTAssertTrue(titleInput.waitForExistence(timeout: 6))

        titleInput.tap()
        titleInput.clearAndEnterText("UI Test Order")

        let createButton = app.buttons["create_order_button"]
        XCTAssertTrue(createButton.exists)
        createButton.tap()

        XCTAssertTrue(app.staticTexts["UI Test Order"].waitForExistence(timeout: 8))
    }

    func testOpenMapShowsLiveStatus() {
        ensureAuthenticated()

        let mapAction = app.buttons["home_action_map"]
        XCTAssertTrue(mapAction.waitForExistence(timeout: 6))
        mapAction.tap()

        let liveStatus = app.staticTexts["live_order_status"]
        XCTAssertTrue(liveStatus.waitForExistence(timeout: 8))
    }

    func testOpenCatalogShowsCollectionOrStateMessage() {
        ensureAuthenticated()

        let catalogAction = app.buttons["home_action_catalog"]
        XCTAssertTrue(catalogAction.waitForExistence(timeout: 6))
        catalogAction.tap()

        let catalogCollection = app.collectionViews["offers_collection_view"]
        let stateMessage = app.staticTexts["offers_state_message"]
        XCTAssertTrue(
            catalogCollection.waitForExistence(timeout: 8) || stateMessage.waitForExistence(timeout: 8)
        )
    }

    func testLogoutReturnsToAuthScreen() {
        ensureAuthenticated()

        let logoutButton = app.buttons["logout_button"]
        XCTAssertTrue(logoutButton.waitForExistence(timeout: 6))
        logoutButton.tap()

        let signInButton = app.buttons["sign_in_button"]
        XCTAssertTrue(signInButton.waitForExistence(timeout: 8))
    }

    func testHomeSearchFiltersCatalogAction() {
        ensureAuthenticated()

        let searchInput = app.textFields["home_search_input"]
        XCTAssertTrue(searchInput.waitForExistence(timeout: 6))
        searchInput.tap()
        searchInput.clearAndEnterText("catalog")

        XCTAssertTrue(app.buttons["home_action_catalog"].waitForExistence(timeout: 6))
    }

    func testOpenOrdersSupportsRefreshAction() {
        ensureAuthenticated()

        let ordersAction = app.buttons["home_action_orders"]
        XCTAssertTrue(ordersAction.waitForExistence(timeout: 6))
        ordersAction.tap()

        let refreshButton = app.buttons["orders_refresh_button"]
        XCTAssertTrue(refreshButton.waitForExistence(timeout: 6))
        refreshButton.tap()

        let ordersList = app.tables["orders_list"]
        let fallbackState = app.staticTexts["orders_title"]
        XCTAssertTrue(ordersList.waitForExistence(timeout: 8) || fallbackState.waitForExistence(timeout: 8))
    }

    func testCriticalScreensExposeAccessibilityAnchors() {
        ensureAuthenticated()

        XCTAssertTrue(app.staticTexts["home_title"].waitForExistence(timeout: 4))
        XCTAssertTrue(app.textFields["home_search_input"].exists)

        let ordersAction = app.buttons["home_action_orders"]
        XCTAssertTrue(ordersAction.waitForExistence(timeout: 6))
        ordersAction.tap()
        XCTAssertTrue(app.staticTexts["orders_title"].waitForExistence(timeout: 6))

        let backButtonFromOrders = app.navigationBars.buttons.element(boundBy: 0)
        if backButtonFromOrders.exists {
            backButtonFromOrders.tap()
        }

        let mapAction = app.buttons["home_action_map"]
        XCTAssertTrue(mapAction.waitForExistence(timeout: 6))
        mapAction.tap()
        XCTAssertTrue(app.staticTexts["map_screen_title"].waitForExistence(timeout: 8))
    }

    private func ensureAuthenticated() {
        let signInButton = app.buttons["sign_in_button"]
        if signInButton.waitForExistence(timeout: 4) {
            let emailInput = app.textFields["email_input"]
            let passwordInput = app.secureTextFields["password_input"]

            XCTAssertTrue(emailInput.exists)
            XCTAssertTrue(passwordInput.exists)

            emailInput.tap()
            emailInput.clearAndEnterText("user@example.com")

            passwordInput.tap()
            passwordInput.clearAndEnterText("123456")

            signInButton.tap()
        }

        XCTAssertTrue(app.buttons["home_action_orders"].waitForExistence(timeout: 8))
    }
}
