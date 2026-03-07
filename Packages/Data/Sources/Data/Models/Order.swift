import Foundation

public struct Order: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let title: String
    public let status: OrderStatus
    public let createdAt: Date

    public init(
        id: UUID = UUID(),
        title: String,
        status: OrderStatus,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.status = status
        self.createdAt = createdAt
    }
}

public enum OrderStatus: String, Codable, CaseIterable, Sendable {
    case pending
    case inProgress
    case completed
    case cancelled
}
