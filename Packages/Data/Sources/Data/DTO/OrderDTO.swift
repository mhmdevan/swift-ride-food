import Foundation

enum APIOrderStatus: String, Codable {
    case pending
    case inProgress = "in_progress"
    case completed
    case cancelled

    func toDomain() -> OrderStatus {
        switch self {
        case .pending:
            return .pending
        case .inProgress:
            return .inProgress
        case .completed:
            return .completed
        case .cancelled:
            return .cancelled
        }
    }
}

struct OrderDTO: Codable {
    let id: UUID
    let title: String
    let status: APIOrderStatus
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case status
        case createdAt = "created_at"
    }

    func toDomain() -> Order {
        Order(
            id: id,
            title: title,
            status: status.toDomain(),
            createdAt: createdAt
        )
    }
}
