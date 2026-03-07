import Foundation

public actor PushNotificationService {
    private let messagingClient: any PushMessagingClient

    public init(messagingClient: any PushMessagingClient) {
        self.messagingClient = messagingClient
    }

    public func configure() async {
        await messagingClient.configureIfNeeded()
    }

    public func didRegisterAPNSToken(_ tokenData: Data) async {
        await messagingClient.updateAPNSToken(tokenData)
    }

    public func currentFCMToken() async -> String? {
        await messagingClient.currentFCMToken()
    }

    public func handleRemoteNotification(userInfo: [AnyHashable: Any]) async -> PushNotificationFetchResult {
        let payload = PushNotificationPayload(userInfo: userInfo)

        if payload.hasOrderStatusUpdate || payload.hasRichContentOverrides {
            return .newData
        }

        return .noData
    }
}
