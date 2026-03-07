import Foundation

public struct User: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let name: String
    public let email: String
    public let updatedAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        email: String,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.updatedAt = updatedAt
    }
}
