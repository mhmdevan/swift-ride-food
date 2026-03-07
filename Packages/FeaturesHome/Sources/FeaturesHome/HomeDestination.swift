public enum HomeDestination: String, CaseIterable, Identifiable, Sendable {
    case auth
    case map
    case orders
    case catalog

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .auth:
            return "Auth"
        case .map:
            return "Map Tracking"
        case .orders:
            return "Orders"
        case .catalog:
            return "Offers (UIKit)"
        }
    }
}
