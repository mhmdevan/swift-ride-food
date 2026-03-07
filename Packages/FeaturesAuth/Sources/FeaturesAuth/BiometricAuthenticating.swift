public protocol BiometricAuthenticating: Sendable {
    func canEvaluate() -> Bool
    func authenticate(reason: String) async -> Bool
}

public struct DisabledBiometricAuthenticator: BiometricAuthenticating {
    public init() {}

    public func canEvaluate() -> Bool {
        false
    }

    public func authenticate(reason: String) async -> Bool {
        _ = reason
        return false
    }
}
