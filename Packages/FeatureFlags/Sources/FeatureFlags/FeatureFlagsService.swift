public actor FeatureFlagsService {
    private let remoteConfigProvider: any RemoteConfigProviding
    private var flags: FeatureFlags

    public init(
        remoteConfigProvider: any RemoteConfigProviding,
        initialFlags: FeatureFlags = .default
    ) {
        self.remoteConfigProvider = remoteConfigProvider
        flags = initialFlags
    }

    @discardableResult
    public func refresh() async -> FeatureFlags {
        do {
            try await remoteConfigProvider.fetchAndActivate()

            let enableWebSocket = await remoteConfigProvider.boolValue(for: .enableWebSocket)
            let enableNewCatalogUI = await remoteConfigProvider.boolValue(for: .enableNewCatalogUI)
            let enableGraphQLOffersBackend = await remoteConfigProvider.boolValue(for: .enableGraphQLOffersBackend)

            flags = FeatureFlags(
                enableWebSocket: enableWebSocket,
                enableNewCatalogUI: enableNewCatalogUI,
                enableGraphQLOffersBackend: enableGraphQLOffersBackend
            )
        } catch {
            // Keep previous values when fetch fails to avoid accidental flag resets.
        }

        return flags
    }

    public func currentFlags() -> FeatureFlags {
        flags
    }
}
