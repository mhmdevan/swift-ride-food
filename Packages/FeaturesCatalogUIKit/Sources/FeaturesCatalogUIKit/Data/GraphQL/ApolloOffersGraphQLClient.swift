#if canImport(Apollo)
@preconcurrency import Apollo
import Foundation

public final class ApolloOffersGraphQLClient: @unchecked Sendable, OffersGraphQLClient {
    private let client: ApolloClient

    public init(client: ApolloClient) {
        self.client = client
    }

    public func fetchOffersPage(after cursor: String?, limit: Int) async throws -> GraphQLOffersPageDTO {
        _ = client
        _ = cursor
        _ = limit
        throw OffersGraphQLError.apolloNotConfigured
    }
}
#endif
