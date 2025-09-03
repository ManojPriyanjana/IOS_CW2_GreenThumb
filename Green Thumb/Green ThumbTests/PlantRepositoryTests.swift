import XCTest
import CoreData
@testable import Green_Thumb   // must match your app module name exactly

final class TaskRepositoryTests: XCTestCase {

    private var container: NSPersistentContainer!
    private var ctx: NSManagedObjectContext!

    override func setUp() {
        super.setUp()
        container = NSPersistentContainer(name: "GreenThumbDataModel")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores(completionHandler: { _, _ in })
        ctx = container.viewContext
    }

    func testWateringTaskDueIn7Days() throws {
        let plant = Plant(context: ctx)
        plant.id = UUID()
        plant.name = "Tomato"
        plant.category = "Vegetables"
        plant.plantingDate = Date()

        let task = Task(context: ctx)
        task.id = UUID()
        task.title = "Water"
        task.type = "watering"
        task.status = "Pending"
        task.createdAt = Date()
        task.dueDate = Calendar.current.date(byAdding: .day, value: 7, to: plant.plantingDate!)
        task.plant = plant

        try ctx.save()

        XCTAssertEqual(task.plant, plant)
    }
}
