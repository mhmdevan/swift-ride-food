import Foundation

public enum OfferSectionStyle: String, Hashable, Sendable {
    case featuredCarousel
    case compactGrid
}

public struct OfferSection: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let title: String
    public let style: OfferSectionStyle
    public let items: [OfferItem]

    public init(
        id: UUID = UUID(),
        title: String,
        style: OfferSectionStyle,
        items: [OfferItem]
    ) {
        self.id = id
        self.title = title
        self.style = style
        self.items = items
    }
}
