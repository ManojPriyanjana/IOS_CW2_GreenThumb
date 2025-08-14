import CoreData

public final class PersistenceController {
    public static let shared = PersistenceController()   // app singleton

    public let container: NSPersistentContainer
    public var context: NSManagedObjectContext { container.viewContext }

    // Disk-backed by default; pass inMemory: true for tests/previews.
    public init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "GreenThumbDataModel")
        if inMemory {
            let desc = NSPersistentStoreDescription()
            desc.type = NSInMemoryStoreType
            container.persistentStoreDescriptions = [desc]
        }
        container.loadPersistentStores { _, error in
            if let error = error { fatalError("Core Data load error: \(error)") }
        }
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    public func saveIfNeeded() {
        let ctx = container.viewContext
        if ctx.hasChanges { try? ctx.save() }
    }
}
