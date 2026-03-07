import Foundation

public struct GraphQLOfferItemDTO: Equatable, Sendable {
    public let id: String
    public let title: String
    public let subtitle: String
    public let priceText: String
    public let badgeText: String?
    public let imageURL: String?

    public init(
        id: String,
        title: String,
        subtitle: String,
        priceText: String,
        badgeText: String?,
        imageURL: String?
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.priceText = priceText
        self.badgeText = badgeText
        self.imageURL = imageURL
    }
}

public struct GraphQLOffersPageDTO: Equatable, Sendable {
    public let items: [GraphQLOfferItemDTO]
    public let nextCursor: String?

    public init(items: [GraphQLOfferItemDTO], nextCursor: String?) {
        self.items = items
        self.nextCursor = nextCursor
    }
}

public enum OffersGraphQLError: Error, Equatable, Sendable {
    case requestFailed
    case invalidPayload
    case apolloNotConfigured
}

public protocol OffersGraphQLClient: Sendable {
    func fetchOffersPage(after cursor: String?, limit: Int) async throws -> GraphQLOffersPageDTO
}
