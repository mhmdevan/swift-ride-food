import Foundation

enum OfferCatalogFixtures {
    static let items: [OfferItem] = [
        OfferItem(
            id: UUID(uuidString: "A0000000-0000-0000-0000-000000000001")!,
            title: "Airport Ride",
            subtitle: "Fixed fare to airport zone",
            priceText: "$18.90",
            badgeText: "-20%",
            imageURL: URL(string: "https://picsum.photos/seed/airportride/420/260")
        ),
        OfferItem(
            id: UUID(uuidString: "A0000000-0000-0000-0000-000000000002")!,
            title: "Family Meal Combo",
            subtitle: "Pizza + drinks + dessert",
            priceText: "$22.40",
            badgeText: "Best Seller",
            imageURL: URL(string: "https://picsum.photos/seed/familycombo/420/260")
        ),
        OfferItem(
            id: UUID(uuidString: "A0000000-0000-0000-0000-000000000003")!,
            title: "Night Express",
            subtitle: "Priority pickup after 10 PM",
            priceText: "$14.10",
            badgeText: "Fast",
            imageURL: URL(string: "https://picsum.photos/seed/nightexpress/420/260")
        ),
        OfferItem(
            id: UUID(uuidString: "A0000000-0000-0000-0000-000000000004")!,
            title: "Burger Set",
            subtitle: "Beef burger + fries",
            priceText: "$8.50",
            imageURL: URL(string: "https://picsum.photos/seed/burgerset/360/220")
        ),
        OfferItem(
            id: UUID(uuidString: "A0000000-0000-0000-0000-000000000005")!,
            title: "City Ride",
            subtitle: "Downtown trip",
            priceText: "$6.90",
            imageURL: URL(string: "https://picsum.photos/seed/cityride/360/220")
        ),
        OfferItem(
            id: UUID(uuidString: "A0000000-0000-0000-0000-000000000006")!,
            title: "Salad Bowl",
            subtitle: "Fresh daily menu",
            priceText: "$7.25",
            imageURL: URL(string: "https://picsum.photos/seed/saladbowl/360/220")
        ),
        OfferItem(
            id: UUID(uuidString: "A0000000-0000-0000-0000-000000000007")!,
            title: "Office Shuttle",
            subtitle: "Business district route",
            priceText: "$9.80",
            imageURL: URL(string: "https://picsum.photos/seed/officeshuttle/360/220")
        ),
        OfferItem(
            id: UUID(uuidString: "A0000000-0000-0000-0000-000000000008")!,
            title: "Sushi Lunch",
            subtitle: "12 pcs + miso soup",
            priceText: "$12.40",
            imageURL: URL(string: "https://picsum.photos/seed/sushilunch/360/220")
        ),
        OfferItem(
            id: UUID(uuidString: "A0000000-0000-0000-0000-000000000009")!,
            title: "Weekend Escape Ride",
            subtitle: "Intercity saver",
            priceText: "$28.10",
            badgeText: "Limited",
            imageURL: URL(string: "https://picsum.photos/seed/weekendride/420/260")
        ),
        OfferItem(
            id: UUID(uuidString: "A0000000-0000-0000-0000-000000000010")!,
            title: "Pasta Duo",
            subtitle: "Two pasta boxes",
            priceText: "$15.30",
            imageURL: URL(string: "https://picsum.photos/seed/pastaduo/360/220")
        ),
        OfferItem(
            id: UUID(uuidString: "A0000000-0000-0000-0000-000000000011")!,
            title: "Airport Return",
            subtitle: "Return route voucher",
            priceText: "$16.70",
            imageURL: URL(string: "https://picsum.photos/seed/airportreturn/360/220")
        ),
        OfferItem(
            id: UUID(uuidString: "A0000000-0000-0000-0000-000000000012")!,
            title: "Chicken Box",
            subtitle: "Spicy strips + dip",
            priceText: "$9.10",
            imageURL: URL(string: "https://picsum.photos/seed/chickenbox/360/220")
        ),
        OfferItem(
            id: UUID(uuidString: "A0000000-0000-0000-0000-000000000013")!,
            title: "Morning Commute",
            subtitle: "Peak-hour discount",
            priceText: "$5.90",
            badgeText: "New",
            imageURL: URL(string: "https://picsum.photos/seed/morningcommute/420/260")
        ),
        OfferItem(
            id: UUID(uuidString: "A0000000-0000-0000-0000-000000000014")!,
            title: "Vegan Bowl",
            subtitle: "Protein-rich menu",
            priceText: "$10.60",
            imageURL: URL(string: "https://picsum.photos/seed/veganbowl/360/220")
        ),
        OfferItem(
            id: UUID(uuidString: "A0000000-0000-0000-0000-000000000015")!,
            title: "Team Lunch Pack",
            subtitle: "5 meals package",
            priceText: "$39.00",
            badgeText: "Office",
            imageURL: URL(string: "https://picsum.photos/seed/teamlunch/420/260")
        ),
        OfferItem(
            id: UUID(uuidString: "A0000000-0000-0000-0000-000000000016")!,
            title: "Late Night Bites",
            subtitle: "Open till 2 AM",
            priceText: "$11.20",
            imageURL: URL(string: "https://picsum.photos/seed/latenightbites/360/220")
        ),
        OfferItem(
            id: UUID(uuidString: "A0000000-0000-0000-0000-000000000017")!,
            title: "Rainy Day Ride",
            subtitle: "Weather-protected pickup",
            priceText: "$7.80",
            imageURL: URL(string: "https://picsum.photos/seed/rainyride/360/220")
        ),
        OfferItem(
            id: UUID(uuidString: "A0000000-0000-0000-0000-000000000018")!,
            title: "Fresh Juice Set",
            subtitle: "3 mixed juices",
            priceText: "$6.40",
            imageURL: URL(string: "https://picsum.photos/seed/freshjuice/360/220")
        ),
        OfferItem(
            id: UUID(uuidString: "A0000000-0000-0000-0000-000000000019")!,
            title: "Premium Sedan",
            subtitle: "Comfort ride class",
            priceText: "$19.90",
            imageURL: URL(string: "https://picsum.photos/seed/premiumsedan/360/220")
        ),
        OfferItem(
            id: UUID(uuidString: "A0000000-0000-0000-0000-000000000020")!,
            title: "Dessert Trio",
            subtitle: "Cakes + brownie + cookie",
            priceText: "$8.95",
            imageURL: URL(string: "https://picsum.photos/seed/desserttrio/360/220")
        )
    ]
}
