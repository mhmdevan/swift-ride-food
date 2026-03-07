import Foundation

public struct PushNotificationPayload: Equatable, Sendable {
    public let orderID: UUID?
    public let status: String?
    public let titleOverride: String?
    public let bodyOverride: String?
    public let subtitleOverride: String?
    public let richImageURL: URL?

    public init(userInfo: [AnyHashable: Any]) {
        let aps = userInfo["aps"] as? [String: Any]
        let alert = aps?["alert"]

        let alertDictionary = alert as? [String: Any]
        let alertBody = alert as? String

        orderID = (userInfo["order_id"] as? String).flatMap(UUID.init(uuidString:))
        status = userInfo["status"] as? String

        titleOverride = (userInfo["rich_title"] as? String) ?? (alertDictionary?["title"] as? String)
        bodyOverride = (userInfo["rich_body"] as? String) ?? (alertDictionary?["body"] as? String) ?? alertBody
        subtitleOverride = (userInfo["rich_subtitle"] as? String) ?? (alertDictionary?["subtitle"] as? String)

        richImageURL = Self.validRichImageURL(from: userInfo["rich_image_url"] as? String)
    }

    public var hasOrderStatusUpdate: Bool {
        guard let status else { return false }
        return orderID != nil && status.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    }

    public var hasRichContentOverrides: Bool {
        titleOverride != nil || bodyOverride != nil || subtitleOverride != nil || richImageURL != nil
    }
}

private extension PushNotificationPayload {
    static func validRichImageURL(from rawValue: String?) -> URL? {
        guard
            let rawValue,
            let url = URL(string: rawValue),
            let scheme = url.scheme?.lowercased(),
            ["http", "https"].contains(scheme),
            url.host?.isEmpty == false
        else {
            return nil
        }

        return url
    }
}
