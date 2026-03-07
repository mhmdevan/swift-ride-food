#if canImport(FirebaseRemoteConfig)
import FirebaseRemoteConfig

public actor FirebaseRemoteConfigProvider: RemoteConfigProviding {
    private let remoteConfig: RemoteConfig

    public init(remoteConfig: RemoteConfig = .remoteConfig()) {
        self.remoteConfig = remoteConfig
    }

    public func fetchAndActivate() async throws {
        _ = try await remoteConfig.fetchAndActivate()
    }

    public func boolValue(for key: FeatureFlagKey) async -> Bool {
        remoteConfig.configValue(forKey: key.rawValue).boolValue
    }
}
#endif
