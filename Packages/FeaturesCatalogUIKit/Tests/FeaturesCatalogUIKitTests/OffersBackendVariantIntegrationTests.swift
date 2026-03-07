import Foundation
import Testing
@testable import FeaturesCatalogUIKit

private func makeGraphQLOffer(id: String, title: String) -> GraphQLOfferItemDTO {
    GraphQLOfferItemDTO(
        id: id,
        title: title,
        subtitle: "Subtitle \(title)",
        priceText: "$10.00",
        badgeText: nil,
        imageURL: "https://example.com/\(title).png"
    )
}

private func makeRestOffer(id: String, title: String) -> OfferItem {
    OfferItem(
        id: UUID(uuidString: id)!,
        title: title,
        subtitle: "Subtitle \(title)",
        priceText: "$11.00"
    )
}

@Test
func graphQLRepositoryLoadsAndCachesFirstPage() async throws {
    let client = FixtureOffersGraphQLClient(
        allItems: [
            makeGraphQLOffer(id: "40000000-0000-0000-0000-000000000001", title: "Graph A"),
            makeGraphQLOffer(id: "40000000-0000-0000-0000-000000000002", title: "Graph B")
        ],
        latencyNanoseconds: 0
    )
    let repository = GraphQLOffersRepository(client: client, cacheTTL: 60)

    let networkPage = try await repository.fetchFirstPage(limit: 2)
    let cachedPage = await repository.cachedFirstPage(limit: 2)

    #expect(networkPage.source == .network)
    #expect(networkPage.items.map(\.title) == ["Graph A", "Graph B"])
    #expect(cachedPage?.source == .cacheFresh)
}

@Test
func graphQLRepositoryFailureFallsBackToRESTRepository() async throws {
    let failingGraphQL = GraphQLOffersRepository(
        client: FixtureOffersGraphQLClient(
            allItems: [makeGraphQLOffer(id: "41000000-0000-0000-0000-000000000001", title: "Graph A")],
            latencyNanoseconds: 0,
            shouldFailRequests: true
        )
    )
    let restRepository = CachedOffersRepository(
        remoteDataSource: RESTOffersRemoteDataSource(
            allItems: [
                makeRestOffer(id: "42000000-0000-0000-0000-000000000001", title: "REST A"),
                makeRestOffer(id: "42000000-0000-0000-0000-000000000002", title: "REST B")
            ],
            latencyNanoseconds: 0
        )
    )
    let repository = FallbackOffersRepository(primary: failingGraphQL, fallback: restRepository)

    let page = try await repository.fetchFirstPage(limit: 2)

    #expect(page.items.map(\.title) == ["REST A", "REST B"])
}

@Test
func graphQLRepositoryFailureIsMappedToUnifiedOffersError() async {
    let failingRepository = GraphQLOffersRepository(
        client: FixtureOffersGraphQLClient(
            allItems: [makeGraphQLOffer(id: "43000000-0000-0000-0000-000000000001", title: "Graph A")],
            latencyNanoseconds: 0,
            shouldFailRequests: true
        )
    )

    do {
        _ = try await failingRepository.fetchFirstPage(limit: 2)
        Issue.record("Expected GraphQL failure")
    } catch let error as OffersDataError {
        #expect(error == .network)
    } catch {
        Issue.record("Unexpected error type: \(error)")
    }
}
