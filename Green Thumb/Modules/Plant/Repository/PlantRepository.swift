import CoreData

protocol PlantRepositoryProtocol {
    func create(name: String, category: String, plantingDate: Date, location: String?, photoData: Data?, notes: String?) throws
    func delete(_ plant: Plant) throws
    func save() throws
}

final class PlantRepository: PlantRepositoryProtocol {
    private let ctx: NSManagedObjectContext
    init(ctx: NSManagedObjectContext) { self.ctx = ctx }

    func create(name: String, category: String, plantingDate: Date, location: String?, photoData: Data?, notes: String?) throws {
        let p = Plant(context: ctx)
        p.id = UUID()
        p.name = name
        p.category = category
        p.plantingDate = plantingDate
        p.location = location
        p.photoData = photoData
        p.notes = notes
        try save()
    }

    func delete(_ plant: Plant) throws {
        ctx.delete(plant)
        try save()
    }

    func save() throws {
        if ctx.hasChanges { try ctx.save() }
    }
}
