import Analytics
import Data
import Foundation
import Testing
@testable import FeaturesOrders

private actor FailingOrderRepository: OrderRepository {
    func fetchOrders(forceRefresh: Bool) async throws -> [Order] {
        _ = forceRefresh
        throw NSError(domain: "test", code: 1)
    }

    func createOrder(title: String) async throws -> Order {
        _ = title
        throw NSError(domain: "test", code: 1)
    }
}

@MainActor
@Test
func loadOrdersProducesEmptyStateWhenRepositoryReturnsNoOrders() async {
    let repository = ReadThroughOrderRepository(
        localStore: InMemoryLocalOrderStore(seed: []),
        remoteDataSource: MockRemoteOrderDataSource(seed: [])
    )
    let viewModel = OrdersViewModel(repository: repository)

    await viewModel.loadOrders()

    if case .empty = viewModel.state {
        return
    } else {
        Issue.record("Expected empty state")
    }
}

@MainActor
@Test
func loadOrdersProducesFailedStateOnRepositoryError() async {
    let repository = FailingOrderRepository()
    let viewModel = OrdersViewModel(repository: repository)

    await viewModel.loadOrders()

    if case .failed = viewModel.state {
        return
    } else {
        Issue.record("Expected failed state")
    }
}

@MainActor
@Test
func createOrderTracksOrderCreatedEventAndRefreshesList() async {
    let repository = ReadThroughOrderRepository(
        localStore: InMemoryLocalOrderStore(seed: []),
        remoteDataSource: MockRemoteOrderDataSource(seed: [])
    )
    let tracker = InMemoryAnalyticsTracker()
    let viewModel = OrdersViewModel(repository: repository, tracker: tracker)

    await viewModel.createOrder(title: "New order")

    let events = await tracker.trackedEvents()
    #expect(events.contains(where: { $0.name == "order_created" }))

    if case let .loaded(orders) = viewModel.state {
        #expect(orders.count == 1)
        #expect(orders.first?.title == "New order")
    } else {
        Issue.record("Expected loaded state after order creation")
    }
}

@MainActor
@Test
func createOrderWithEmptyTitleProducesValidationError() async {
    let repository = ReadThroughOrderRepository(
        localStore: InMemoryLocalOrderStore(seed: []),
        remoteDataSource: MockRemoteOrderDataSource(seed: [])
    )
    let viewModel = OrdersViewModel(repository: repository)

    await viewModel.createOrder(title: "   ")

    if case let .failed(error) = viewModel.state {
        #expect(error == .validation(message: "Order title cannot be empty."))
    } else {
        Issue.record("Expected failed validation state")
    }
}
