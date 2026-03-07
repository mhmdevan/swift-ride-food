import Foundation
import Testing
@testable import FeaturesCatalogUIKit

private enum UnknownError: Error {
    case value
}

@Test
func offersDataErrorMapsNetworkAndTimeoutErrors() {
    #expect(OffersDataError.map(URLError(.notConnectedToInternet)) == .network)
    #expect(OffersDataError.map(URLError(.timedOut)) == .timeout)
}

@Test
func offersDataErrorMapsDecodingAndGraphQLErrors() {
    let decodingError = DecodingError.dataCorrupted(
        DecodingError.Context(codingPath: [], debugDescription: "Invalid payload")
    )

    #expect(OffersDataError.map(decodingError) == .decoding)
    #expect(OffersDataError.map(OffersGraphQLError.invalidPayload) == .decoding)
    #expect(OffersDataError.map(OffersGraphQLError.requestFailed) == .network)
}

@Test
func offersDataErrorMapsUnknownErrorToUnknown() {
    #expect(OffersDataError.map(UnknownError.value) == .unknown)
}

@Test
func offersDataErrorProvidesContextAwareMessages() {
    #expect(
        OffersDataError.network.message(for: .initialLoad) == "No internet connection. Please try again."
    )
    #expect(
        OffersDataError.timeout.message(for: .pagination) == "Connection issue while loading more offers."
    )
    #expect(
        OffersDataError.server(statusCode: 500).message(for: .refreshWithCache)
            == "Unable to refresh offers. Showing latest cached data."
    )
}
