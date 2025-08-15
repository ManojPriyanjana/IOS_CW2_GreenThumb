import Foundation
import CoreData

protocol TaskRepositoryProtocol {
    func fetch(_ filter: TaskFilter) throws -> [TaskItem]
    func get(id: UUID) throws -> TaskItem?
    func upsert(_ task: TaskItem) throws
    func delete(ids: [UUID]) throws
}

final class TaskRepository: TaskRepositoryProtocol {
    private let ctx: NSManagedObjectContext
    init(context: NSManagedObjectContext = TaskCoreData.viewContext) { self.ctx = context }

    func fetch(_ filter: TaskFilter) throws -> [TaskItem] {
        let req = NSFetchRequest<NSManagedObject>(entityName: "TaskEntity")
        var preds: [NSPredicate] = []
        let now = Date()
        switch filter {
        case .done: preds.append(NSPredicate(format: "isCompleted == YES"))
        case .health: preds.append(NSPredicate(format: "typeRaw == %d", TaskType.healthCheck.rawValue))
        case .today:
            let cal = Calendar.current
            let start = cal.startOfDay(for: now)
            let end = cal.date(byAdding: .day, value: 1, to: start)!
            preds.append(NSPredicate(format: "isCompleted == NO"))
            preds.append(NSPredicate(format: "dueDate >= %@ AND dueDate < %@", start as NSDate, end as NSDate))
        case .upcoming:
            preds.append(NSPredicate(format: "isCompleted == NO"))
            preds.append(NSPredicate(format: "dueDate > %@", now as NSDate))
        case .overdue:
            preds.append(NSPredicate(format: "isCompleted == NO"))
            preds.append(NSPredicate(format: "dueDate != nil AND dueDate < %@", now as NSDate))
        case .all:
            break
        }
        if !preds.isEmpty { req.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: preds) }
        req.sortDescriptors = [
            NSSortDescriptor(key: "isCompleted", ascending: true),
            NSSortDescriptor(key: "dueDate", ascending: true),
            NSSortDescriptor(key: "createdAt", ascending: false)
        ]
        return try ctx.fetch(req).compactMap { Self.mapToDomain($0) }
    }

    func get(id: UUID) throws -> TaskItem? {
        let req = NSFetchRequest<NSManagedObject>(entityName: "TaskEntity")
        req.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        req.fetchLimit = 1
        return try ctx.fetch(req).first.flatMap(Self.mapToDomain(_:))
    }

    func upsert(_ task: TaskItem) throws {
        let req = NSFetchRequest<NSManagedObject>(entityName: "TaskEntity")
        req.predicate = NSPredicate(format: "id == %@", task.id as CVarArg)
        req.fetchLimit = 1
        let obj = try ctx.fetch(req).first ?? NSEntityDescription.insertNewObject(forEntityName: "TaskEntity", into: ctx)
        Self.mapFromDomain(task, into: obj)
        try ctx.save()
    }

    func delete(ids: [UUID]) throws {
        guard !ids.isEmpty else { return }
        let req = NSFetchRequest<NSManagedObject>(entityName: "TaskEntity")
        req.predicate = NSPredicate(format: "id IN %@", ids)
        for obj in try ctx.fetch(req) { ctx.delete(obj) }
        try ctx.save()
    }

    // MARK: - Mapping
    private static func mapToDomain(_ obj: NSManagedObject) -> TaskItem? {
        guard
            let id = obj.value(forKey: "id") as? UUID,
            let title = obj.value(forKey: "title") as? String,
            let createdAt = obj.value(forKey: "createdAt") as? Date,
            let updatedAt = obj.value(forKey: "updatedAt") as? Date
        else { return nil }

        let type = TaskType(rawValue: obj.value(forKey: "typeRaw") as? Int16 ?? 0) ?? .watering
        let unit = RepeatUnit(rawValue: obj.value(forKey: "repeatUnitRaw") as? Int16 ?? 0) ?? .day
        let recur = RecurrenceRule(every: Int(obj.value(forKey: "repeatEvery") as? Int16 ?? 0), unit: unit)
        return TaskItem(
            id: id,
            title: title,
            notes: obj.value(forKey: "notes") as? String,
            type: type,
            priority: Int(obj.value(forKey: "priority") as? Int16 ?? 0),
            startDate: obj.value(forKey: "startDate") as? Date,
            dueDate: obj.value(forKey: "dueDate") as? Date,
            remindAt: obj.value(forKey: "remindAt") as? Date,
            isCompleted: obj.value(forKey: "isCompleted") as? Bool ?? false,
            isWeatherAware: obj.value(forKey: "isWeatherAware") as? Bool ?? false,
            recurrence: recur,
            plantId: obj.value(forKey: "plantId") as? UUID,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    private static func mapFromDomain(_ t: TaskItem, into obj: NSManagedObject) {
        obj.setValue(t.id, forKey: "id")
        obj.setValue(t.title, forKey: "title")
        obj.setValue(t.notes, forKey: "notes")
        obj.setValue(t.type.rawValue, forKey: "typeRaw")
        obj.setValue(Int16(t.priority), forKey: "priority")
        obj.setValue(t.startDate, forKey: "startDate")
        obj.setValue(t.dueDate, forKey: "dueDate")
        obj.setValue(t.remindAt, forKey: "remindAt")
        obj.setValue(t.isCompleted, forKey: "isCompleted")
        obj.setValue(t.isWeatherAware, forKey: "isWeatherAware")
        obj.setValue(Int16(t.recurrence.every), forKey: "repeatEvery")
        obj.setValue(t.recurrence.unit.rawValue, forKey: "repeatUnitRaw")
        obj.setValue(t.plantId, forKey: "plantId")
        obj.setValue(t.createdAt, forKey: "createdAt")
        obj.setValue(Date(), forKey: "updatedAt")
    }
}
