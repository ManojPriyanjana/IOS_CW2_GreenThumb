import CoreData

/// Repository for CareTask CRUD.
final class TaskRepository {
    private let ctx: NSManagedObjectContext
    init(ctx: NSManagedObjectContext) { self.ctx = ctx }

    @discardableResult
    func create(for plant: Plant?, title: String, type: String, dueDate: Date?, priority: Int16) throws -> CareTask {
        let t = CareTask(context: ctx)
        t.id = UUID()
        t.title = title
        t.type = type
        t.status = "Pending"
        t.createdAt = Date()
        t.priority = priority
        t.dueDate = dueDate
        t.plant = plant          // ← can be nil (make relationship Optional in model)
        try save()
        return t
    }

    func markCompleted(_ task: CareTask) throws {
        task.status = "Completed"
        try save()
    }

    func delete(_ task: CareTask) throws {
        ctx.delete(task)
        try save()
    }

    // Private
    private func save() throws {
        if ctx.hasChanges { try ctx.save() }
    }
}
