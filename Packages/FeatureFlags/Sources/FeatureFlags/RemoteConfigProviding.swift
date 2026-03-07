public protocol RemoteConfigProviding: Sendable {
    func fetchAndActivate() async throws
    func boolValue(for key: FeatureFlagKey) async -> Bool
}
