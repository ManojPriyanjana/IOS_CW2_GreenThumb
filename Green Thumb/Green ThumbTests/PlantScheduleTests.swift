import XCTest
import CoreData
@testable import Green_Thumb

final class PlantScheduleTests: XCTestCase {

    private var persistence: PersistenceController!
    private var ctx: NSManagedObjectContext!

    override func setUp() {
        super.setUp()
        // isolated in-memory stack for tests
        persistence = PersistenceController(inMemory: true)
        ctx = persistence.context
    }

    override func tearDown() {
        persistence = nil
        ctx = nil
        super.tearDown()
    }

    func testNextWateringDateIsSevenDays() throws {
        // GIVEN
        let plant = Plant(context: ctx)
        plant.id = UUID()
        plant.commonName = "Test Monstera"
        plant.healthStatus = "healthy"
        plant.lightLevel = "indirect"
        plant.dateAdded = Date(timeIntervalSince1970: 0) // 1970-01-01
        plant.wateringFreqDays = 7
        plant.fertilizeFreqDays = 30
        plant.lastWatered = plant.dateAdded

        try ctx.save()

        // WHEN
        let last = plant.lastWatered!
        let next = Calendar.current.date(byAdding: .day,
                                         value: Int(plant.wateringFreqDays),
                                         to: last)!

        // THEN
        let comps = Calendar.current.dateComponents([.day],
                                                    from: plant.dateAdded!,
                                                    to: next)
        XCTAssertEqual(comps.day, 7)
    }
}
