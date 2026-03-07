import Foundation

public actor RESTOffersRemoteDataSource: OffersRemoteDataSource {
    private let allItems: [OfferItem]
    private let latencyNanoseconds: UInt64

    public init(
        allItems: [OfferItem]? = nil,
        latencyNanoseconds: UInt64 = 140_000_000
    ) {
        self.allItems = allItems ?? OfferCatalogFixtures.items
        self.latencyNanoseconds = latencyNanoseconds
    }

    public func fetchPage(after cursor: String?, limit: Int) async throws -> OffersRemotePage {
        do {
            try await Task.sleep(nanoseconds: latencyNanoseconds)

            let normalizedLimit = max(1, limit)
            let parsedStartIndex: Int
            if let cursor {
                guard let index = Int(cursor), index >= 0 else {
                    throw OffersDataError.decoding
                }
                parsedStartIndex = index
            } else {
                parsedStartIndex = 0
            }

            let startIndex = min(parsedStartIndex, allItems.count)
            let endIndex = min(allItems.count, startIndex + normalizedLimit)
            let pageItems = Array(allItems[startIndex..<endIndex])

            let nextCursor: String?
            if endIndex < allItems.count {
                nextCursor = String(endIndex)
            } else {
                nextCursor = nil
            }

            return OffersRemotePage(items: pageItems, nextCursor: nextCursor)
        } catch {
            throw OffersDataError.map(error)
        }
    }
}
