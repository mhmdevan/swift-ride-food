import Foundation

public actor GraphQLOffersRepository: OffersRepository {
    private let cachedRepository: CachedOffersRepository

    public init(
        client: any OffersGraphQLClient = FixtureOffersGraphQLClient(),
        cache: any OffersFirstPageCaching = InMemoryOffersFirstPageCache(),
        cacheTTL: TimeInterval = 15 * 60,
        now: @escaping @Sendable () -> Date = Date.init
    ) {
        cachedRepository = CachedOffersRepository(
            remoteDataSource: GraphQLOffersRemoteDataSource(client: client),
            cache: cache,
            cacheTTL: cacheTTL,
            now: now
        )
    }

    public func cachedFirstPage(limit: Int) async -> OffersPage? {
        await cachedRepository.cachedFirstPage(limit: limit)
    }

    public func fetchFirstPage(limit: Int) async throws -> OffersPage {
        try await cachedRepository.fetchFirstPage(limit: limit)
    }

    public func fetchNextPage(after cursor: String, limit: Int) async throws -> OffersPage {
        try await cachedRepository.fetchNextPage(after: cursor, limit: limit)
    }
}
