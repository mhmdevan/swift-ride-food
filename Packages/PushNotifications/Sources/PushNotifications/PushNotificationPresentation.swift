import Foundation

public struct PushNotificationPresentation: Equatable, Sendable {
    public let title: String
    public let body: String
    public let subtitle: String
    public let richImageURL: URL?

    public init(title: String, body: String, subtitle: String, richImageURL: URL?) {
        self.title = title
        self.body = body
        self.subtitle = subtitle
        self.richImageURL = richImageURL
    }
}
