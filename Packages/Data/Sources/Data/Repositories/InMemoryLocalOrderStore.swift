import Foundation

public actor InMemoryLocalOrderStore: LocalOrderStore {
    private var storage: [Order]

    public init(seed: [Order] = []) {
        self.storage = seed
    }

    public func fetchOrders() async throws -> [Order] {
        storage.sorted { $0.createdAt > $1.createdAt }
    }

    public func save(orders: [Order]) async throws {
        storage = orders
    }

    public func append(order: Order) async throws {
        storage.insert(order, at: 0)
    }
}
