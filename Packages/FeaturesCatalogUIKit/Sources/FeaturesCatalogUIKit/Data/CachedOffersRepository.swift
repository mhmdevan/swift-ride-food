import Foundation

public actor CachedOffersRepository: OffersRepository {
    private let remoteDataSource: any OffersRemoteDataSource
    private let cache: any OffersFirstPageCaching
    private let cacheTTL: TimeInterval
    private let maximumStaleAge: TimeInterval
    private let allowedClockSkew: TimeInterval
    private let now: @Sendable () -> Date

    public init(
        remoteDataSource: any OffersRemoteDataSource,
        cache: any OffersFirstPageCaching = InMemoryOffersFirstPageCache(),
        cacheTTL: TimeInterval = 15 * 60,
        maximumStaleAge: TimeInterval = 24 * 60 * 60,
        allowedClockSkew: TimeInterval = 2 * 60,
        now: @escaping @Sendable () -> Date = Date.init
    ) {
        self.remoteDataSource = remoteDataSource
        self.cache = cache
        self.cacheTTL = max(1, cacheTTL)
        self.maximumStaleAge = max(cacheTTL, maximumStaleAge)
        self.allowedClockSkew = max(0, allowedClockSkew)
        self.now = now
    }

    public func cachedFirstPage(limit: Int) async -> OffersPage? {
        guard let entry = await cache.cachedPage(limit: limit) else {
            return nil
        }

        let age = now().timeIntervalSince(entry.savedAt)
        if age < -allowedClockSkew || age > maximumStaleAge {
            await cache.invalidate(limit: limit)
            return nil
        }
        let source: OffersPageSource = age <= cacheTTL ? .cacheFresh : .cacheStale
        return OffersPage(items: entry.page.items, nextCursor: entry.page.nextCursor, source: source)
    }

    public func fetchFirstPage(limit: Int) async throws -> OffersPage {
        do {
            let page = try await remoteDataSource.fetchPage(after: nil, limit: limit)
            await cache.save(page: page, limit: limit, savedAt: now())
            return OffersPage(items: page.items, nextCursor: page.nextCursor, source: .network)
        } catch {
            throw OffersDataError.map(error)
        }
    }

    public func fetchNextPage(after cursor: String, limit: Int) async throws -> OffersPage {
        do {
            let page = try await remoteDataSource.fetchPage(after: cursor, limit: limit)
            return OffersPage(items: page.items, nextCursor: page.nextCursor, source: .network)
        } catch {
            throw OffersDataError.map(error)
        }
    }
}
