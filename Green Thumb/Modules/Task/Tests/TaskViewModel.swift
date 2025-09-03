
import CoreData

final class TaskViewModel: ObservableObject {
    private let ctx: NSManagedObjectContext
    init(ctx: NSManagedObjectContext) { self.ctx = ctx }

    func add(for plant: Plant, title: String, type: String, due: Date?, priority: Int16) {
        do { _ = try TaskRepository(ctx: ctx).create(for: plant, title: title, type: type, dueDate: due, priority: priority) }
        catch { print("Task add error:", error) }
    }

    func complete(_ t: CareTask) { do { try TaskRepository(ctx: ctx).markCompleted(t) } catch { print(error) } }
    func delete(_ t: CareTask) { do { try TaskRepository(ctx: ctx).delete(t) } catch { print(error) } }
}
