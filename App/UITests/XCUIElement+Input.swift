import XCTest

extension XCUIElement {
    func clearAndEnterText(_ text: String) {
        guard let existingValue = value as? String else {
            typeText(text)
            return
        }

        tap()
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: existingValue.count)
        typeText(deleteString + text)
    }
}
