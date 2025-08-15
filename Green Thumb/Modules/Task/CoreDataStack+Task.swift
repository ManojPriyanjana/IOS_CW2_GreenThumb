// Modules/Task/CoreDataStack+Task.swift
import CoreData

enum TaskCoreData {
    static let modelName = "GreenThumbDataModel"  // must match your .xcdatamodeld name

    static let container: NSPersistentContainer = {
        let c = NSPersistentContainer(name: modelName)
        c.loadPersistentStores { _, error in
            if let error = error { fatalError("Task CoreData load error: \(error)") }
        }
        c.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        c.viewContext.automaticallyMergesChangesFromParent = true
        return c
    }()

    static var viewContext: NSManagedObjectContext { container.viewContext }
    static func bgContext() -> NSManagedObjectContext { container.newBackgroundContext() }
}
