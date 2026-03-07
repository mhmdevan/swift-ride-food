import Foundation

public actor FixtureOffersGraphQLClient: OffersGraphQLClient {
    private let allItems: [GraphQLOfferItemDTO]
    private let latencyNanoseconds: UInt64
    private var shouldFailRequests: Bool

    public init(
        allItems: [GraphQLOfferItemDTO]? = nil,
        latencyNanoseconds: UInt64 = 100_000_000,
        shouldFailRequests: Bool = false
    ) {
        if let allItems {
            self.allItems = allItems
        } else {
            self.allItems = OfferCatalogFixtures.items.map {
                GraphQLOfferItemDTO(
                    id: $0.id.uuidString,
                    title: $0.title,
                    subtitle: $0.subtitle,
                    priceText: $0.priceText,
                    badgeText: $0.badgeText,
                    imageURL: $0.imageURL?.absoluteString
                )
            }
        }
        self.latencyNanoseconds = latencyNanoseconds
        self.shouldFailRequests = shouldFailRequests
    }

    public func fetchOffersPage(after cursor: String?, limit: Int) async throws -> GraphQLOffersPageDTO {
        if shouldFailRequests {
            throw OffersGraphQLError.requestFailed
        }

        try await Task.sleep(nanoseconds: latencyNanoseconds)

        let normalizedLimit = max(1, limit)
        let startIndex = max(0, Int(cursor ?? "0") ?? 0)
        let endIndex = min(allItems.count, startIndex + normalizedLimit)
        let items = Array(allItems[startIndex..<endIndex])
        let nextCursor = endIndex < allItems.count ? String(endIndex) : nil

        return GraphQLOffersPageDTO(items: items, nextCursor: nextCursor)
    }

    public func setFailureMode(_ shouldFail: Bool) {
        shouldFailRequests = shouldFail
    }
}
