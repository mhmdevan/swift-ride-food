import Foundation
import Testing
@testable import FeaturesCatalogUIKit

private enum RemoteError: Error {
    case failed
}

private actor StubOffersRemoteDataSource: OffersRemoteDataSource {
    var pagesByCursor: [String?: Result<OffersRemotePage, Error>]
    private(set) var requests: [String?] = []

    init(pagesByCursor: [String?: Result<OffersRemotePage, Error>]) {
        self.pagesByCursor = pagesByCursor
    }

    func fetchPage(after cursor: String?, limit: Int) async throws -> OffersRemotePage {
        _ = limit
        requests.append(cursor)
        guard let result = pagesByCursor[cursor] else {
            throw RemoteError.failed
        }
        return try result.get()
    }

    func requestedCursors() -> [String?] {
        requests
    }
}

private func makeOffer(id: String, title: String) -> OfferItem {
    OfferItem(
        id: UUID(uuidString: id)!,
        title: title,
        subtitle: title,
        priceText: "$10"
    )
}

@Test
func cachedRepositoryReturnsFreshCacheWithinTTL() async throws {
    let firstPage = OffersRemotePage(
        items: [makeOffer(id: "30000000-0000-0000-0000-000000000001", title: "A")],
        nextCursor: nil
    )
    let remote = StubOffersRemoteDataSource(pagesByCursor: [nil: .success(firstPage)])
    let cache = InMemoryOffersFirstPageCache()
    let now = Date(timeIntervalSince1970: 1_000)
    let repository = CachedOffersRepository(
        remoteDataSource: remote,
        cache: cache,
        cacheTTL: 60,
        now: { now }
    )

    _ = try await repository.fetchFirstPage(limit: 5)
    let cached = await repository.cachedFirstPage(limit: 5)

    #expect(cached?.source == .cacheFresh)
    #expect(cached?.items.count == 1)
}

@Test
func cachedRepositoryMarksCacheAsStaleAfterTTL() async throws {
    let firstPage = OffersRemotePage(
        items: [makeOffer(id: "31000000-0000-0000-0000-000000000001", title: "A")],
        nextCursor: nil
    )
    let remote = StubOffersRemoteDataSource(pagesByCursor: [nil: .success(firstPage)])
    let cache = InMemoryOffersFirstPageCache()
    let savedAt = Date(timeIntervalSince1970: 2_000)
    let repository = CachedOffersRepository(
        remoteDataSource: remote,
        cache: cache,
        cacheTTL: 10,
        now: { savedAt.addingTimeInterval(30) }
    )

    await cache.save(page: firstPage, limit: 5, savedAt: savedAt)

    let cached = await repository.cachedFirstPage(limit: 5)
    #expect(cached?.source == .cacheStale)
}

@Test
func cachedRepositoryInvalidatesCacheWhenEntryIsTooOld() async throws {
    let firstPage = OffersRemotePage(
        items: [makeOffer(id: "31500000-0000-0000-0000-000000000001", title: "Stale")],
        nextCursor: nil
    )
    let remote = StubOffersRemoteDataSource(pagesByCursor: [nil: .success(firstPage)])
    let cache = InMemoryOffersFirstPageCache()
    let now = Date(timeIntervalSince1970: 3_000)
    let repository = CachedOffersRepository(
        remoteDataSource: remote,
        cache: cache,
        cacheTTL: 30,
        maximumStaleAge: 90,
        now: { now }
    )

    await cache.save(page: firstPage, limit: 5, savedAt: now.addingTimeInterval(-120))

    let cached = await repository.cachedFirstPage(limit: 5)
    let rawEntry = await cache.cachedPage(limit: 5)

    #expect(cached == nil)
    #expect(rawEntry == nil)
}

@Test
func cachedRepositoryInvalidatesCacheWhenSavedAtIsInFuture() async throws {
    let firstPage = OffersRemotePage(
        items: [makeOffer(id: "31600000-0000-0000-0000-000000000001", title: "Future")],
        nextCursor: nil
    )
    let remote = StubOffersRemoteDataSource(pagesByCursor: [nil: .success(firstPage)])
    let cache = InMemoryOffersFirstPageCache()
    let now = Date(timeIntervalSince1970: 4_000)
    let repository = CachedOffersRepository(
        remoteDataSource: remote,
        cache: cache,
        cacheTTL: 30,
        maximumStaleAge: 300,
        allowedClockSkew: 10,
        now: { now }
    )

    await cache.save(page: firstPage, limit: 5, savedAt: now.addingTimeInterval(60))

    let cached = await repository.cachedFirstPage(limit: 5)
    let rawEntry = await cache.cachedPage(limit: 5)

    #expect(cached == nil)
    #expect(rawEntry == nil)
}

@Test
func fallbackRepositoryUsesFallbackWhenPrimaryFails() async throws {
    let fallbackPage = OffersRemotePage(
        items: [makeOffer(id: "32000000-0000-0000-0000-000000000001", title: "Fallback")],
        nextCursor: nil
    )

    let failingRemote = StubOffersRemoteDataSource(pagesByCursor: [nil: .failure(RemoteError.failed)])
    let fallbackRemote = StubOffersRemoteDataSource(pagesByCursor: [nil: .success(fallbackPage)])
    let primaryRepository = CachedOffersRepository(remoteDataSource: failingRemote)
    let fallbackRepository = CachedOffersRepository(remoteDataSource: fallbackRemote)
    let repository = FallbackOffersRepository(primary: primaryRepository, fallback: fallbackRepository)

    let page = try await repository.fetchFirstPage(limit: 10)
    #expect(page.items.first?.title == "Fallback")
}

@Test
func graphQLRemoteDataSourceMapsDTOToDomain() async throws {
    let client = FixtureOffersGraphQLClient(
        allItems: [
            GraphQLOfferItemDTO(
                id: "33000000-0000-0000-0000-000000000001",
                title: "GraphQL A",
                subtitle: "Subtitle",
                priceText: "$11",
                badgeText: nil,
                imageURL: "https://example.com/image.png"
            )
        ],
        latencyNanoseconds: 0
    )
    let dataSource = GraphQLOffersRemoteDataSource(client: client)

    let page = try await dataSource.fetchPage(after: nil, limit: 5)

    #expect(page.items.count == 1)
    #expect(page.items.first?.title == "GraphQL A")
}

@Test
func graphQLRemoteDataSourceFailsOnInvalidUUID() async throws {
    let client = FixtureOffersGraphQLClient(
        allItems: [
            GraphQLOfferItemDTO(
                id: "invalid-id",
                title: "Broken",
                subtitle: "Broken",
                priceText: "$1",
                badgeText: nil,
                imageURL: nil
            )
        ],
        latencyNanoseconds: 0
    )
    let dataSource = GraphQLOffersRemoteDataSource(client: client)

    do {
        _ = try await dataSource.fetchPage(after: nil, limit: 5)
        Issue.record("Expected invalid payload failure")
    } catch let error as OffersDataError {
        #expect(error == .decoding)
    }
}
