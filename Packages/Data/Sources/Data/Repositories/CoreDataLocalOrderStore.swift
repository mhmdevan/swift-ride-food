import CoreData
import Foundation

public final class CoreDataLocalOrderStore: LocalOrderStore, @unchecked Sendable {
    private let context: NSManagedObjectContext

    public init(coreDataStack: CoreDataStack) {
        context = coreDataStack.makeBackgroundContext()
    }

    public func fetchOrders() async throws -> [Order] {
        let context = self.context

        return try await perform(on: context) {
            let request = NSFetchRequest<NSManagedObject>(entityName: "OrderEntity")
            request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]

            let entities = try context.fetch(request)
            return try entities.map { try Self.mapOrder(from: $0) }
        }
    }

    public func save(orders: [Order]) async throws {
        let context = self.context

        try await perform(on: context) {
            let request = NSFetchRequest<NSManagedObject>(entityName: "OrderEntity")
            let existingEntities = try context.fetch(request)
            var entitiesByID: [UUID: NSManagedObject] = [:]

            for entity in existingEntities {
                if let id = entity.value(forKey: "id") as? UUID {
                    entitiesByID[id] = entity
                }
            }

            let incomingIDs = Set(orders.map(\.id))

            for order in orders {
                let entity = entitiesByID[order.id]
                    ?? NSManagedObject(entity: Self.orderEntityDescription(in: context), insertInto: context)
                entity.setValue(order.id, forKey: "id")
                entity.setValue(order.title, forKey: "title")
                entity.setValue(order.status.rawValue, forKey: "status")
                entity.setValue(order.createdAt, forKey: "createdAt")
            }

            for existing in existingEntities {
                guard let id = existing.value(forKey: "id") as? UUID else {
                    continue
                }

                if incomingIDs.contains(id) == false {
                    context.delete(existing)
                }
            }

            if context.hasChanges {
                try context.save()
            }
        }
    }

    public func append(order: Order) async throws {
        let context = self.context

        try await perform(on: context) {
            let request = NSFetchRequest<NSManagedObject>(entityName: "OrderEntity")
            request.fetchLimit = 1
            request.predicate = NSPredicate(format: "id == %@", order.id as CVarArg)

            let existing = try context.fetch(request).first
            let entity = existing
                ?? NSManagedObject(entity: Self.orderEntityDescription(in: context), insertInto: context)

            entity.setValue(order.id, forKey: "id")
            entity.setValue(order.title, forKey: "title")
            entity.setValue(order.status.rawValue, forKey: "status")
            entity.setValue(order.createdAt, forKey: "createdAt")

            if context.hasChanges {
                try context.save()
            }
        }
    }

    private func perform<T>(on context: NSManagedObjectContext, _ operation: @escaping () throws -> T) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            context.perform {
                do {
                    continuation.resume(returning: try operation())
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private static func orderEntityDescription(in context: NSManagedObjectContext) -> NSEntityDescription {
        guard let description = NSEntityDescription.entity(forEntityName: "OrderEntity", in: context) else {
            preconditionFailure("OrderEntity is not defined in CoreData model.")
        }

        return description
    }

    private static func mapOrder(from entity: NSManagedObject) throws -> Order {
        guard let id = entity.value(forKey: "id") as? UUID,
              let title = entity.value(forKey: "title") as? String,
              let statusRawValue = entity.value(forKey: "status") as? String,
              let status = OrderStatus(rawValue: statusRawValue),
              let createdAt = entity.value(forKey: "createdAt") as? Date else {
            throw NSError(domain: "CoreDataLocalOrderStore", code: 1)
        }

        return Order(
            id: id,
            title: title,
            status: status,
            createdAt: createdAt
        )
    }
}
