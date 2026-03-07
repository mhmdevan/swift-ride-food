public struct FeatureFlags: Equatable, Sendable {
    public var enableWebSocket: Bool
    public var enableNewCatalogUI: Bool
    public var enableGraphQLOffersBackend: Bool

    public init(
        enableWebSocket: Bool,
        enableNewCatalogUI: Bool,
        enableGraphQLOffersBackend: Bool
    ) {
        self.enableWebSocket = enableWebSocket
        self.enableNewCatalogUI = enableNewCatalogUI
        self.enableGraphQLOffersBackend = enableGraphQLOffersBackend
    }

    public static let `default` = FeatureFlags(
        enableWebSocket: true,
        enableNewCatalogUI: true,
        enableGraphQLOffersBackend: false
    )
}
