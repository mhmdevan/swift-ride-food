public actor ReadThroughOrderRepository: OrderRepository {
    private let localStore: any LocalOrderStore
    private let remoteDataSource: any RemoteOrderDataSource

    public init(localStore: any LocalOrderStore, remoteDataSource: any RemoteOrderDataSource) {
        self.localStore = localStore
        self.remoteDataSource = remoteDataSource
    }

    public func fetchOrders(forceRefresh: Bool = false) async throws -> [Order] {
        let localOrders = try await localStore.fetchOrders()

        if forceRefresh {
            return try await refreshAndMerge(localOrders: localOrders)
        }

        if localOrders.isEmpty == false {
            Task {
                await refreshInBackground(cachedOrders: localOrders)
            }
            return localOrders
        }

        return try await refreshAndMerge(localOrders: localOrders)
    }

    public func createOrder(title: String) async throws -> Order {
        let createdOrder = try await remoteDataSource.createOrder(title: title)
        try await localStore.append(order: createdOrder)
        return createdOrder
    }

    private func refreshAndMerge(localOrders: [Order]) async throws -> [Order] {
        let remoteOrders = try await remoteDataSource.fetchOrders()
        let mergedOrders = Self.merge(local: localOrders, remote: remoteOrders)
        try await localStore.save(orders: mergedOrders)
        return mergedOrders
    }

    private func refreshInBackground(cachedOrders: [Order]) async {
        do {
            let remoteOrders = try await remoteDataSource.fetchOrders()
            let mergedOrders = Self.merge(local: cachedOrders, remote: remoteOrders)
            try await localStore.save(orders: mergedOrders)
        } catch {
            // Ignore background refresh errors and keep local cache available offline.
        }
    }

    private static func merge(local: [Order], remote: [Order]) -> [Order] {
        var mergedByID: [Order.ID: Order] = [:]

        for order in local {
            mergedByID[order.id] = order
        }

        for order in remote {
            mergedByID[order.id] = order
        }

        return mergedByID.values.sorted { $0.createdAt > $1.createdAt }
    }
}
