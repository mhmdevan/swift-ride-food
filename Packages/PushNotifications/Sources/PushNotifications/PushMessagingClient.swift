import Foundation

public protocol PushMessagingClient: Sendable {
    func configureIfNeeded() async
    func updateAPNSToken(_ tokenData: Data) async
    func currentFCMToken() async -> String?
}
