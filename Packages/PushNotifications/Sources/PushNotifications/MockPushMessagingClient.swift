import Foundation

public actor MockPushMessagingClient: PushMessagingClient {
    private var isConfigured = false
    private var fcmToken: String?

    public init() {}

    public func configureIfNeeded() async {
        isConfigured = true
    }

    public func updateAPNSToken(_ tokenData: Data) async {
        let tokenHex = tokenData.map { String(format: "%02x", $0) }.joined()
        fcmToken = "fcm_\(tokenHex.prefix(12))"
    }

    public func currentFCMToken() async -> String? {
        fcmToken
    }

    public func configuredState() async -> Bool {
        isConfigured
    }

    public func setFCMToken(_ token: String?) async {
        fcmToken = token
    }
}
