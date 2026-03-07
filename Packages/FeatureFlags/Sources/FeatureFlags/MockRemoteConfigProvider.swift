import Foundation

public actor MockRemoteConfigProvider: RemoteConfigProviding {
    private var values: [FeatureFlagKey: Bool]
    private var shouldFailFetch: Bool

    public init(
        values: [FeatureFlagKey: Bool] = [
            .enableWebSocket: true,
            .enableNewCatalogUI: true,
            .enableGraphQLOffersBackend: false
        ],
        shouldFailFetch: Bool = false
    ) {
        self.values = values
        self.shouldFailFetch = shouldFailFetch
    }

    public func fetchAndActivate() async throws {
        if shouldFailFetch {
            throw NSError(
                domain: "MockRemoteConfigProvider",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Remote config fetch failed."]
            )
        }
    }

    public func boolValue(for key: FeatureFlagKey) async -> Bool {
        values[key] ?? false
    }

    public func setValue(_ value: Bool, for key: FeatureFlagKey) {
        values[key] = value
    }

    public func setFetchFailure(_ value: Bool) {
        shouldFailFetch = value
    }
}
