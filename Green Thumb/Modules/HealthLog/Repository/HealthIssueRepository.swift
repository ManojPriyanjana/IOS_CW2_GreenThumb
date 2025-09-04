import CoreData

/// CRUD for HealthIssue
final class HealthIssueRepository {
    private let ctx: NSManagedObjectContext
    init(ctx: NSManagedObjectContext) { self.ctx = ctx }

    @discardableResult
    func create(for plant: Plant,
                category: String,
                subtype: String?,
                notes: String?) throws -> HealthIssue {
        let issue = HealthIssue(context: ctx)
        issue.id = UUID()
        issue.category = category
        issue.subtype = (subtype?.isEmpty == true) ? nil : subtype
        issue.notes = (notes?.isEmpty == true) ? nil : notes
        issue.status = "Open"
        issue.createdAt = Date()
        issue.resolvedAt = nil
        issue.plant = plant
        try save()
        return issue
    }

    func resolve(_ issue: HealthIssue) throws {
        issue.status = "Resolved"
        issue.resolvedAt = Date()
        try save()
    }

    func reopen(_ issue: HealthIssue) throws {
        issue.status = "Open"
        issue.resolvedAt = nil
        try save()
    }

    func delete(_ issue: HealthIssue) throws {
        ctx.delete(issue)
        try save()
    }

    // private
    private func save() throws {
        if ctx.hasChanges { try ctx.save() }
    }
}
