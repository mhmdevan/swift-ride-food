#if canImport(FirebaseMessaging)
import FirebaseMessaging
import Foundation

public actor FirebaseMessagingClient: PushMessagingClient {
    public init() {}

    public func configureIfNeeded() async {
        // Firebase Messaging is configured once FirebaseApp is configured in app startup.
    }

    public func updateAPNSToken(_ tokenData: Data) async {
        Messaging.messaging().apnsToken = tokenData
    }

    public func currentFCMToken() async -> String? {
        Messaging.messaging().fcmToken
    }
}
#endif
