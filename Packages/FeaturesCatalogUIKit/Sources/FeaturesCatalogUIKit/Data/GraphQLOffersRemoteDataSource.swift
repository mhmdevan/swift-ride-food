import Foundation

public actor GraphQLOffersRemoteDataSource: OffersRemoteDataSource {
    private let client: any OffersGraphQLClient

    public init(client: any OffersGraphQLClient = FixtureOffersGraphQLClient()) {
        self.client = client
    }

    public func fetchPage(after cursor: String?, limit: Int) async throws -> OffersRemotePage {
        do {
            let dto = try await client.fetchOffersPage(after: cursor, limit: limit)
            let items = try dto.items.map { itemDTO in
                guard let uuid = UUID(uuidString: itemDTO.id) else {
                    throw OffersDataError.decoding
                }

                return OfferItem(
                    id: uuid,
                    title: itemDTO.title,
                    subtitle: itemDTO.subtitle,
                    priceText: itemDTO.priceText,
                    badgeText: itemDTO.badgeText,
                    imageURL: itemDTO.imageURL.flatMap(URL.init(string:))
                )
            }

            return OffersRemotePage(items: items, nextCursor: dto.nextCursor)
        } catch {
            throw OffersDataError.map(error)
        }
    }
}
