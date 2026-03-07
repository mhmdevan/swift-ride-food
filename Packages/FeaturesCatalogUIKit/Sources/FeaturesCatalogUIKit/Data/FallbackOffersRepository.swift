import Foundation

public actor FallbackOffersRepository: OffersRepository {
    private let primary: any OffersRepository
    private let fallback: any OffersRepository

    public init(primary: any OffersRepository, fallback: any OffersRepository) {
        self.primary = primary
        self.fallback = fallback
    }

    public func cachedFirstPage(limit: Int) async -> OffersPage? {
        if let primaryPage = await primary.cachedFirstPage(limit: limit) {
            return primaryPage
        }
        return await fallback.cachedFirstPage(limit: limit)
    }

    public func fetchFirstPage(limit: Int) async throws -> OffersPage {
        do {
            return try await primary.fetchFirstPage(limit: limit)
        } catch {
            return try await fallback.fetchFirstPage(limit: limit)
        }
    }

    public func fetchNextPage(after cursor: String, limit: Int) async throws -> OffersPage {
        do {
            return try await primary.fetchNextPage(after: cursor, limit: limit)
        } catch {
            return try await fallback.fetchNextPage(after: cursor, limit: limit)
        }
    }
}
