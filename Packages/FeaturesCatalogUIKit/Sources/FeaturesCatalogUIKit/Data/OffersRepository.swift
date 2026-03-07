import Foundation

public enum OffersPageSource: Equatable, Sendable {
    case network
    case cacheFresh
    case cacheStale
}

public struct OffersPage: Equatable, Sendable {
    public let items: [OfferItem]
    public let nextCursor: String?
    public let source: OffersPageSource

    public init(items: [OfferItem], nextCursor: String?, source: OffersPageSource) {
        self.items = items
        self.nextCursor = nextCursor
        self.source = source
    }
}

public enum OffersBackendVariant: String, Equatable, Sendable {
    case rest
    case graphQL
}

public protocol OffersRepository: Sendable {
    func cachedFirstPage(limit: Int) async -> OffersPage?
    func fetchFirstPage(limit: Int) async throws -> OffersPage
    func fetchNextPage(after cursor: String, limit: Int) async throws -> OffersPage
}
