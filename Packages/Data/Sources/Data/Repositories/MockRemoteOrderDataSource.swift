import Foundation

public actor MockRemoteOrderDataSource: RemoteOrderDataSource {
    private var orders: [Order]
    private let latencyNanoseconds: UInt64

    public init(seed: [Order] = [], latencyNanoseconds: UInt64 = 50_000_000) {
        self.orders = seed
        self.latencyNanoseconds = latencyNanoseconds
    }

    public func fetchOrders() async throws -> [Order] {
        try await Task.sleep(nanoseconds: latencyNanoseconds)
        return orders.sorted { $0.createdAt > $1.createdAt }
    }

    public func fetchOrder(id: UUID) async throws -> Order {
        try await Task.sleep(nanoseconds: latencyNanoseconds)

        guard let order = orders.first(where: { $0.id == id }) else {
            throw NSError(domain: "MockRemoteOrderDataSource", code: 404)
        }

        return order
    }

    public func createOrder(title: String) async throws -> Order {
        try await Task.sleep(nanoseconds: latencyNanoseconds)
        let order = Order(title: title, status: .pending)
        orders.insert(order, at: 0)
        return order
    }
}
