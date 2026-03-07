import Foundation

public struct OffersRemotePage: Equatable, Sendable {
    public let items: [OfferItem]
    public let nextCursor: String?

    public init(items: [OfferItem], nextCursor: String?) {
        self.items = items
        self.nextCursor = nextCursor
    }
}

public protocol OffersRemoteDataSource: Sendable {
    func fetchPage(after cursor: String?, limit: Int) async throws -> OffersRemotePage
}
