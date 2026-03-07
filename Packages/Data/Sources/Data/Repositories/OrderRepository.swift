import Foundation

public protocol OrderRepository: Sendable {
    func fetchOrders(forceRefresh: Bool) async throws -> [Order]
    func createOrder(title: String) async throws -> Order
}

public protocol LocalOrderStore: Sendable {
    func fetchOrders() async throws -> [Order]
    func save(orders: [Order]) async throws
    func append(order: Order) async throws
}

public protocol RemoteOrderDataSource: Sendable {
    func fetchOrders() async throws -> [Order]
    func fetchOrder(id: UUID) async throws -> Order
    func createOrder(title: String) async throws -> Order
}
