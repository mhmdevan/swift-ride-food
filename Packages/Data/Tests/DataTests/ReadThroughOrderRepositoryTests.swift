import Foundation
import Testing
@testable import Data

@Test
func fetchOrdersReturnsCacheWhenAvailable() async throws {
    let localOrder = Order(title: "Cached order", status: .pending)
    let localStore = InMemoryLocalOrderStore(seed: [localOrder])
    let remoteStore = MockRemoteOrderDataSource(seed: [Order(title: "Remote order", status: .completed)])
    let repository = ReadThroughOrderRepository(localStore: localStore, remoteDataSource: remoteStore)

    let orders = try await repository.fetchOrders(forceRefresh: false)

    #expect(orders.first?.title == "Cached order")
}

@Test
func fetchOrdersLoadsRemoteWhenCacheEmpty() async throws {
    let remoteOrder = Order(title: "Remote order", status: .completed)
    let localStore = InMemoryLocalOrderStore(seed: [])
    let remoteStore = MockRemoteOrderDataSource(seed: [remoteOrder])
    let repository = ReadThroughOrderRepository(localStore: localStore, remoteDataSource: remoteStore)

    let orders = try await repository.fetchOrders(forceRefresh: false)

    #expect(orders == [remoteOrder])
}

@Test
func fetchOrdersRefreshesLocalCacheInBackground() async throws {
    let sharedID = UUID()
    let localOrder = Order(
        id: sharedID,
        title: "Trip #1",
        status: .pending,
        createdAt: Date(timeIntervalSince1970: 100)
    )
    let remoteUpdatedOrder = Order(
        id: sharedID,
        title: "Trip #1",
        status: .completed,
        createdAt: Date(timeIntervalSince1970: 100)
    )
    let remoteNewOrder = Order(
        id: UUID(),
        title: "Trip #2",
        status: .inProgress,
        createdAt: Date(timeIntervalSince1970: 200)
    )

    let localStore = InMemoryLocalOrderStore(seed: [localOrder])
    let remoteStore = MockRemoteOrderDataSource(seed: [remoteUpdatedOrder, remoteNewOrder], latencyNanoseconds: 10_000_000)
    let repository = ReadThroughOrderRepository(localStore: localStore, remoteDataSource: remoteStore)

    let immediateOrders = try await repository.fetchOrders(forceRefresh: false)
    #expect(immediateOrders.count == 1)
    #expect(immediateOrders.first?.status == .pending)

    try await Task.sleep(nanoseconds: 80_000_000)

    let refreshedOrders = try await localStore.fetchOrders()
    #expect(refreshedOrders.count == 2)
    #expect(refreshedOrders.first?.id == remoteNewOrder.id)
    #expect(refreshedOrders.first(where: { $0.id == sharedID })?.status == .completed)
}

@Test
func forceRefreshMergesRemoteWithLocalOrders() async throws {
    let localOnlyOrder = Order(title: "Offline local order", status: .pending)
    let remoteOrder = Order(title: "Remote order", status: .completed)

    let localStore = InMemoryLocalOrderStore(seed: [localOnlyOrder])
    let remoteStore = MockRemoteOrderDataSource(seed: [remoteOrder])
    let repository = ReadThroughOrderRepository(localStore: localStore, remoteDataSource: remoteStore)

    let mergedOrders = try await repository.fetchOrders(forceRefresh: true)

    #expect(mergedOrders.count == 2)
    #expect(mergedOrders.contains(where: { $0.id == localOnlyOrder.id }))
    #expect(mergedOrders.contains(where: { $0.id == remoteOrder.id }))
}

@Test
func createOrderPersistsToLocalStore() async throws {
    let localStore = InMemoryLocalOrderStore(seed: [])
    let remoteStore = MockRemoteOrderDataSource(seed: [])
    let repository = ReadThroughOrderRepository(localStore: localStore, remoteDataSource: remoteStore)

    _ = try await repository.createOrder(title: "New order")
    let cachedOrders = try await localStore.fetchOrders()

    #expect(cachedOrders.count == 1)
    #expect(cachedOrders.first?.title == "New order")
}
