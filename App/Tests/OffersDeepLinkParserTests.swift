@testable import SwiftRideFood
import XCTest

final class OffersDeepLinkParserTests: XCTestCase {
    private let parser = OffersDeepLinkParser()

    func testParsesCustomSchemeOfferRoute() throws {
        let offerID = "A0000000-0000-0000-0000-000000000001"
        let url = try XCTUnwrap(URL(string: "swiftridefood://offers/\(offerID)"))

        let result = parser.parse(url)

        XCTAssertEqual(
            result,
            .target(
                OffersDeepLinkTarget(
                    offerID: try XCTUnwrap(UUID(uuidString: offerID)),
                    source: .customScheme
                )
            )
        )
    }

    func testParsesUniversalLinkOfferRoute() throws {
        let offerID = "A0000000-0000-0000-0000-000000000002"
        let url = try XCTUnwrap(URL(string: "https://app.swiftridefood.com/offers/\(offerID)"))

        let result = parser.parse(url)

        XCTAssertEqual(
            result,
            .target(
                OffersDeepLinkTarget(
                    offerID: try XCTUnwrap(UUID(uuidString: offerID)),
                    source: .universalLink
                )
            )
        )
    }

    func testIgnoresUnrelatedURL() throws {
        let url = try XCTUnwrap(URL(string: "myapp://login?token=abc"))

        let result = parser.parse(url)

        XCTAssertEqual(result, .notApplicable)
    }

    func testRejectsInvalidUUID() throws {
        let url = try XCTUnwrap(URL(string: "swiftridefood://offers/not-a-uuid"))

        let result = parser.parse(url)

        XCTAssertEqual(result, .failure(.invalidOfferIdentifier))
    }

    func testRejectsInvalidUniversalLinkPath() throws {
        let url = try XCTUnwrap(URL(string: "https://app.swiftridefood.com/orders/1"))

        let result = parser.parse(url)

        XCTAssertEqual(result, .failure(.invalidPath))
    }

    func testFailureReasonProvidesUserFacingMessage() {
        XCTAssertEqual(
            OffersDeepLinkFailureReason.invalidOfferIdentifier.userMessage,
            "This offer link has an invalid identifier."
        )
    }
}
