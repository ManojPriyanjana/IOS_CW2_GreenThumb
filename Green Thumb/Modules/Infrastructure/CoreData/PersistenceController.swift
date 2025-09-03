import CoreData

final class PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    // Convenience alias (so your App file can use `.context`)
    var context: NSManagedObjectContext { container.viewContext }

    // Init
    init(inMemory: Bool = false) {
        // IMPORTANT: This must match your .xcdatamodeld name
        container = NSPersistentContainer(name: "GreenThumbDataModel")

        if inMemory {
            let description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
            container.persistentStoreDescriptions = [description]
        }

        // Safer defaults
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true

        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                // Don’t crash your app in production; log instead
                print("❗️Core Data load error:", error, error.userInfo)
            }
        }
    }

    // Save helper
    func saveContext() {
        let ctx = container.viewContext
        guard ctx.hasChanges else { return }
        do { try ctx.save() }
        catch {
            print("❗️Core Data save error:", (error as NSError), (error as NSError).userInfo)
        }
    }
}
