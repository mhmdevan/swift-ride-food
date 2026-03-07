import Foundation

public struct OfferItem: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let title: String
    public let subtitle: String
    public let priceText: String
    public let badgeText: String?
    public let imageURL: URL?

    public init(
        id: UUID = UUID(),
        title: String,
        subtitle: String,
        priceText: String,
        badgeText: String? = nil,
        imageURL: URL? = nil
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.priceText = priceText
        self.badgeText = badgeText
        self.imageURL = imageURL
    }
}
