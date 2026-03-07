import Foundation
import Testing
@testable import Networking

@Test
func redactedURLStringMasksSensitiveQueryParameters() throws {
    let url = try #require(
        URL(string: "https://api.swiftridefood.com/login?email=user@example.com&token=abc123&next=home")
    )

    let redacted = NetworkLogSanitizer.redactedURLString(url)

    #expect(redacted.contains("email=REDACTED"))
    #expect(redacted.contains("token=REDACTED"))
    #expect(redacted.contains("next=home"))
}

@Test
func redactedURLStringHandlesMissingURL() {
    let redacted = NetworkLogSanitizer.redactedURLString(nil)

    #expect(redacted == "-")
}

@Test
func redactedURLStringKeepsNonSensitiveKeysIntact() throws {
    let url = try #require(URL(string: "https://api.swiftridefood.com/offers?page=2&sort=popular"))

    let redacted = NetworkLogSanitizer.redactedURLString(url)

    #expect(redacted.contains("page=2"))
    #expect(redacted.contains("sort=popular"))
}
