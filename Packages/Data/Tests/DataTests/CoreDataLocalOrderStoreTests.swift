import Foundation
import Testing
@testable import Data

@Test
func coreDataModelContainsOrderAndUserEntities() {
    let stack = CoreDataStack(inMemory: true)

    let entities = Set(stack.container.managedObjectModel.entities.compactMap(\.name))

    #expect(entities.contains("OrderEntity"))
    #expect(entities.contains("UserEntity"))
}

@Test
func coreDataLocalOrderStoreSavesAndFetchesOrders() async throws {
    let stack = CoreDataStack(inMemory: true)
    let store = CoreDataLocalOrderStore(coreDataStack: stack)

    let orders = [
        Order(id: UUID(), title: "Order #1", status: .pending, createdAt: Date(timeIntervalSince1970: 10)),
        Order(id: UUID(), title: "Order #2", status: .inProgress, createdAt: Date(timeIntervalSince1970: 20))
    ]

    try await store.save(orders: orders)

    let loaded = try await store.fetchOrders()

    #expect(loaded.count == 2)
    #expect(loaded.first?.title == "Order #2")
}

@Test
func coreDataLocalOrderStoreAppendUpsertsByIdentifier() async throws {
    let stack = CoreDataStack(inMemory: true)
    let store = CoreDataLocalOrderStore(coreDataStack: stack)
    let sharedID = UUID()

    let initialOrder = Order(id: sharedID, title: "Order", status: .pending, createdAt: Date(timeIntervalSince1970: 10))
    try await store.append(order: initialOrder)

    let updatedOrder = Order(id: sharedID, title: "Order", status: .completed, createdAt: Date(timeIntervalSince1970: 10))
    try await store.append(order: updatedOrder)

    let loaded = try await store.fetchOrders()

    #expect(loaded.count == 1)
    #expect(loaded.first?.status == .completed)
}
