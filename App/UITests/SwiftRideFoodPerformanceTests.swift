import XCTest

final class SwiftRideFoodPerformanceTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    func testLaunchPerformance() {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            app.launch()
            app.terminate()
        }
    }

    func testCatalogNavigationClockMetric() {
        app.launch()
        ensureAuthenticated()

        measure(metrics: [XCTClockMetric()]) {
            let catalogAction = app.buttons["home_action_catalog"]
            if catalogAction.waitForExistence(timeout: 3) {
                catalogAction.tap()
            }

            let collection = app.collectionViews["offers_collection_view"]
            _ = collection.waitForExistence(timeout: 5)

            let backButton = app.navigationBars.buttons.element(boundBy: 0)
            if backButton.exists {
                backButton.tap()
            }
        }
    }

    private func ensureAuthenticated() {
        let signInButton = app.buttons["sign_in_button"]
        if signInButton.waitForExistence(timeout: 3) {
            let emailInput = app.textFields["email_input"]
            let passwordInput = app.secureTextFields["password_input"]

            if emailInput.waitForExistence(timeout: 3) {
                emailInput.tap()
                emailInput.clearAndEnterText("user@example.com")
            }

            if passwordInput.waitForExistence(timeout: 3) {
                passwordInput.tap()
                passwordInput.clearAndEnterText("123456")
            }

            signInButton.tap()
        }

        _ = app.buttons["home_action_catalog"].waitForExistence(timeout: 8)
    }
}
