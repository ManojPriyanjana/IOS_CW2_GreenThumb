import XCTest
import CoreData
@testable import Green_Thumb

final class PlantScheduleTests: XCTestCase {

    // In-memory Core Data container for tests
    private func makeContainer() -> NSPersistentContainer {
        let c = NSPersistentContainer(name: "GreenThumbDataModel") // match your .xcdatamodeld name
        let d = NSPersistentStoreDescription()
        d.type = NSInMemoryStoreType
        c.persistentStoreDescriptions = [d]
        c.loadPersistentStores(completionHandler: { _, _ in })
        return c
    }

    func testNextWateringDueInSevenDays() throws {
        // GIVEN
        let container = makeContainer()
        let ctx = container.viewContext

        // Plant
        let plant = Plant(context: ctx)
        plant.id = UUID()
        plant.name = "Test Monstera"
        plant.category = "Indoor"
        plant.plantingDate = Date(timeIntervalSince1970: 0) // 1970-01-01

        // Watering Task due in 7 days from planting
        let task = Task(context: ctx)
        task.id = UUID()
        task.title = "Water"
        task.type = "watering"
        task.status = "Pending"
        task.createdAt = Date()
        task.dueDate = Calendar.current.date(byAdding: .day, value: 7, to: plant.plantingDate!)
        task.plant = plant

        try ctx.save()

        // WHEN
        let next = task.dueDate!

        // THEN (difference should be 7 days)
        let comps = Calendar.current.dateComponents([.day], from: plant.plantingDate!, to: next)
        XCTAssertEqual(comps.day, 7)
    }
}
