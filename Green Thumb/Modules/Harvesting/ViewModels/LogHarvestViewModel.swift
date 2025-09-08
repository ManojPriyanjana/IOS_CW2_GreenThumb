import Foundation
import CoreData

final class LogHarvestViewModel: ObservableObject {
    @Published var actualDate: Date = Date()
    @Published var quantity: Double = 0
    @Published var unit: String = "kg"
    @Published var quality: String = ""
    @Published var notes: String = ""
    @Published var photoData: Data?

    private let schedule: HarvestSchedule
    private let ctx: NSManagedObjectContext

    init(ctx: NSManagedObjectContext, schedule: HarvestSchedule) {
        self.ctx = ctx
        self.schedule = schedule
    }

    func save() {
        do {
            try HarvestRepository.addLog(
                to: schedule,
                actualDate: actualDate,
                quantity: quantity,
                unit: unit,
                quality: quality.isEmpty ? nil : quality,
                notes: notes.isEmpty ? nil : notes,
                photoData: photoData,
                in: ctx
            )
        } catch {
            print("Log save error:", error)
        }
    }
}
