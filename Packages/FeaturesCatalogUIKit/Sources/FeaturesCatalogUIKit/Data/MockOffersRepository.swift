import Foundation

public actor MockOffersRepository: OffersRepository {
    private let remote: RESTOffersRemoteDataSource
    private let cache: InMemoryOffersFirstPageCache

    public init(latencyNanoseconds: UInt64 = 120_000_000) {
        remote = RESTOffersRemoteDataSource(
            allItems: OfferCatalogFixtures.items,
            latencyNanoseconds: latencyNanoseconds
        )
        cache = InMemoryOffersFirstPageCache()
    }

    public func cachedFirstPage(limit: Int) async -> OffersPage? {
        if let entry = await cache.cachedPage(limit: limit) {
            return OffersPage(items: entry.page.items, nextCursor: entry.page.nextCursor, source: .cacheFresh)
        }
        return nil
    }

    public func fetchFirstPage(limit: Int) async throws -> OffersPage {
        let page = try await remote.fetchPage(after: nil, limit: limit)
        await cache.save(page: page, limit: limit, savedAt: Date())
        return OffersPage(items: page.items, nextCursor: page.nextCursor, source: .network)
    }

    public func fetchNextPage(after cursor: String, limit: Int) async throws -> OffersPage {
        let page = try await remote.fetchPage(after: cursor, limit: limit)
        return OffersPage(items: page.items, nextCursor: page.nextCursor, source: .network)
    }
}
