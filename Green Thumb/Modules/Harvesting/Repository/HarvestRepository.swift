import Foundation
import CoreData

enum HarvestStatus: String {
    case planned     = "Planned"
    case due         = "Due"
    case overdue     = "Overdue"
    case completed   = "Completed"
}

/// Centralized CRUD & helpers to keep Views light and future-proof.
final class HarvestRepository {

    // Fetch

    static func fetchSchedules(for plant: Plant, in ctx: NSManagedObjectContext) -> [HarvestSchedule] {
        let req = NSFetchRequest<HarvestSchedule>(entityName: "HarvestSchedule")
        req.predicate = NSPredicate(format: "plant == %@", plant)
        req.sortDescriptors = [
            NSSortDescriptor(key: "expectedStart", ascending: true)
        ]
        do { return try ctx.fetch(req) } catch { print("Fetch schedules error:", error); return [] }
    }

    static func fetchAllUpcoming(in ctx: NSManagedObjectContext, limit: Int? = nil) -> [HarvestSchedule] {
        let req = NSFetchRequest<HarvestSchedule>(entityName: "HarvestSchedule")
        let now = Date()
        // Show planned/due/overdue (not completed)
        req.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "status != %@", HarvestStatus.completed.rawValue),
            NSPredicate(format: "expectedStart != nil"),
            NSPredicate(format: "expectedStart <= %@", now as NSDate? ?? NSDate())
        ])
        req.sortDescriptors = [NSSortDescriptor(key: "expectedStart", ascending: true)]
        if let limit { req.fetchLimit = limit }
        do { return try ctx.fetch(req) } catch { print("Fetch upcoming error:", error); return [] }
    }

    // Create / Update / Delete Schedule

    static func addSchedule(
        for plant: Plant,
        expectedStart: Date,
        expectedEnd: Date?,
        scheduleType: String,
        reminderID: String?,
        notes: String?,
        in ctx: NSManagedObjectContext
    ) throws {
        let schedule = HarvestSchedule(context: ctx)
        schedule.id = UUID()
        schedule.expectedStart = expectedStart
        schedule.expectedEnd = expectedEnd
        schedule.scheduleType = scheduleType
        schedule.reminderID = reminderID
        schedule.notes = notes
        schedule.status = HarvestStatus.planned.rawValue
        schedule.plant = plant
        try ctx.save()
    }

    static func updateSchedule(
        _ schedule: HarvestSchedule,
        expectedStart: Date,
        expectedEnd: Date?,
        scheduleType: String,
        reminderID: String?,
        notes: String?,
        in ctx: NSManagedObjectContext
    ) throws {
        schedule.expectedStart = expectedStart
        schedule.expectedEnd = expectedEnd
        schedule.scheduleType = scheduleType
        schedule.reminderID = reminderID
        schedule.notes = notes
        // Keep status consistent
        schedule.status = computeStatus(for: schedule).rawValue
        try ctx.save()
    }

    static func deleteSchedule(_ schedule: HarvestSchedule, in ctx: NSManagedObjectContext) throws {
        ctx.delete(schedule)
        try ctx.save()
    }

    // MARK: - Log Actual Harvest

    @discardableResult
    static func addLog(
        to schedule: HarvestSchedule,
        actualDate: Date,
        quantity: Double,
        unit: String,
        quality: String?,
        notes: String?,
        photoData: Data?,
        in ctx: NSManagedObjectContext
    ) throws -> HarvestLog {
        let log = HarvestLog(context: ctx)
        log.id = UUID()
        log.actualDate = actualDate
        log.quantity = quantity
        log.unit = unit
        log.quality = quality
        log.notes = notes
        log.photoData = photoData
        log.schedule = schedule

        // If schedule is one-off, auto-complete when a log exists
        if (schedule.scheduleType ?? "").lowercased().contains("one") {
            schedule.status = HarvestStatus.completed.rawValue
        } else {
            // Otherwise refresh status based on dates
            schedule.status = computeStatus(for: schedule).rawValue
        }
        try ctx.save()
        return log
    }

    static func deleteLog(_ log: HarvestLog, in ctx: NSManagedObjectContext) throws {
        ctx.delete(log)
        // Refresh schedule status after deletion
        if let schedule = log.schedule {
            schedule.status = computeStatus(for: schedule).rawValue
        }
        try ctx.save()
    }

    // MARK: - Status

    static func computeStatus(for schedule: HarvestSchedule, now: Date = .now) -> HarvestStatus {
        // Completed if user marked so or one-off with any logs
        if schedule.status == HarvestStatus.completed.rawValue {
            return .completed
        }
        if let logs = schedule.logs as? Set<HarvestLog>, !logs.isEmpty,
           (schedule.scheduleType ?? "").lowercased().contains("one") {
            return .completed
        }

        guard let start = schedule.expectedStart else { return .planned }
        let end = schedule.expectedEnd

        if start > now {
            return .planned
        }
        if let end, end < now {
            return .overdue
        }
        return .due
    }

    static func refreshStatus(_ schedule: HarvestSchedule, in ctx: NSManagedObjectContext) {
        schedule.status = computeStatus(for: schedule).rawValue
        do { try ctx.save() } catch { print("refreshStatus save error:", error) }
    }
}
