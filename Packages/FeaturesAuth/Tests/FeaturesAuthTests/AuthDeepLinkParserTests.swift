import Foundation
import Testing
@testable import FeaturesAuth

@Test
func parserExtractsTokenFromExpectedRoute() throws {
    let parser = AuthDeepLinkParser()
    let url = try #require(URL(string: "myapp://login?token=abc123"))

    #expect(parser.token(from: url) == "abc123")
}

@Test
func parserRejectsUnexpectedRoutes() throws {
    let parser = AuthDeepLinkParser()
    let url = try #require(URL(string: "myapp://orders?token=abc123"))

    #expect(parser.token(from: url) == nil)
}
