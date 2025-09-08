import Foundation
import CoreData

final class AddEditHarvestScheduleViewModel: ObservableObject {
    @Published var expectedStart: Date
    @Published var expectedEnd: Date?
    @Published var scheduleType: String
    @Published var reminderID: String?
    @Published var notes: String?

    private let schedule: HarvestSchedule?
    private let plant: Plant?
    private let ctx: NSManagedObjectContext

    init(ctx: NSManagedObjectContext, plant: Plant) {
        self.ctx = ctx
        self.plant = plant
        self.schedule = nil
        self.expectedStart = Date()
        self.expectedEnd = nil
        self.scheduleType = "One-off"
        self.reminderID = nil
        self.notes = nil
    }

    init(ctx: NSManagedObjectContext, schedule: HarvestSchedule) {
        self.ctx = ctx
        self.schedule = schedule
        self.plant = schedule.plant
        self.expectedStart = schedule.expectedStart ?? Date()
        self.expectedEnd = schedule.expectedEnd
        self.scheduleType = schedule.scheduleType ?? "One-off"
        self.reminderID = schedule.reminderID
        self.notes = schedule.notes
    }

    func save() {
        do {
            if let schedule {
                try HarvestRepository.updateSchedule(
                    schedule,
                    expectedStart: expectedStart,
                    expectedEnd: expectedEnd,
                    scheduleType: scheduleType,
                    reminderID: reminderID,
                    notes: notes,
                    in: ctx
                )
            } else if let plant {
                try HarvestRepository.addSchedule(
                    for: plant,
                    expectedStart: expectedStart,
                    expectedEnd: expectedEnd,
                    scheduleType: scheduleType,
                    reminderID: reminderID,
                    notes: notes,
                    in: ctx
                )
            }
        } catch {
            print("Add/Edit schedule save error:", error)
        }
    }
}
