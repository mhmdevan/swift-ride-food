import CoreData
import Foundation

public final class CoreDataStack: @unchecked Sendable {
    public let container: NSPersistentContainer

    public init(inMemory: Bool = false) {
        container = NSPersistentContainer(
            name: "SwiftRideFoodModel",
            managedObjectModel: Self.managedObjectModel
        )

        if inMemory {
            let description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
            container.persistentStoreDescriptions = [description]
        }

        container.loadPersistentStores { _, error in
            if let error {
                assertionFailure("Failed to load CoreData stack: \(error)")
            }
        }

        container.viewContext.mergePolicy = NSMergePolicy(merge: .mergeByPropertyObjectTrumpMergePolicyType)
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    public func makeBackgroundContext() -> NSManagedObjectContext {
        let context = container.newBackgroundContext()
        context.mergePolicy = NSMergePolicy(merge: .mergeByPropertyObjectTrumpMergePolicyType)
        return context
    }

    private static var managedObjectModel: NSManagedObjectModel {
        let model = NSManagedObjectModel()

        let orderEntity = NSEntityDescription()
        orderEntity.name = "OrderEntity"
        orderEntity.managedObjectClassName = NSStringFromClass(NSManagedObject.self)

        let orderID = NSAttributeDescription()
        orderID.name = "id"
        orderID.attributeType = .UUIDAttributeType
        orderID.isOptional = false

        let orderTitle = NSAttributeDescription()
        orderTitle.name = "title"
        orderTitle.attributeType = .stringAttributeType
        orderTitle.isOptional = false

        let orderStatus = NSAttributeDescription()
        orderStatus.name = "status"
        orderStatus.attributeType = .stringAttributeType
        orderStatus.isOptional = false

        let orderCreatedAt = NSAttributeDescription()
        orderCreatedAt.name = "createdAt"
        orderCreatedAt.attributeType = .dateAttributeType
        orderCreatedAt.isOptional = false

        let orderUserID = NSAttributeDescription()
        orderUserID.name = "userID"
        orderUserID.attributeType = .UUIDAttributeType
        orderUserID.isOptional = true

        orderEntity.properties = [orderID, orderTitle, orderStatus, orderCreatedAt, orderUserID]

        let userEntity = NSEntityDescription()
        userEntity.name = "UserEntity"
        userEntity.managedObjectClassName = NSStringFromClass(NSManagedObject.self)

        let userID = NSAttributeDescription()
        userID.name = "id"
        userID.attributeType = .UUIDAttributeType
        userID.isOptional = false

        let userName = NSAttributeDescription()
        userName.name = "name"
        userName.attributeType = .stringAttributeType
        userName.isOptional = false

        let userEmail = NSAttributeDescription()
        userEmail.name = "email"
        userEmail.attributeType = .stringAttributeType
        userEmail.isOptional = false

        let userUpdatedAt = NSAttributeDescription()
        userUpdatedAt.name = "updatedAt"
        userUpdatedAt.attributeType = .dateAttributeType
        userUpdatedAt.isOptional = false

        userEntity.properties = [userID, userName, userEmail, userUpdatedAt]

        model.entities = [orderEntity, userEntity]

        return model
    }
}
