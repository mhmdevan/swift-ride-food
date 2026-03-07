import Foundation

enum AppRoute: Hashable {
    case auth
    case map
    case orders
    case catalog
    case offerDetail(id: UUID)
}
