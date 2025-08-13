import Foundation

@MainActor
final class AddEditPlantViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var species: String = ""
    @Published var location: String = ""
    @Published var wateringIntervalDays: Int = 7
    @Published var lastWatered: Date? = nil
    @Published var notes: String = ""

    private(set) var editingID: UUID?

    init(existing plant: Plant? = nil) {
        if let p = plant {
            editingID = p.id
            name = p.name
            species = p.species
            location = p.location
            wateringIntervalDays = p.wateringIntervalDays
            lastWatered = p.lastWatered
            notes = p.notes
        }
    }

    var canSave: Bool { !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    func build() -> Plant {
        Plant(
            id: editingID ?? UUID(),
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            species: species.trimmingCharacters(in: .whitespacesAndNewlines),
            location: location.trimmingCharacters(in: .whitespacesAndNewlines),
            lastWatered: lastWatered,
            wateringIntervalDays: max(1, wateringIntervalDays),
            notes: notes
        )
    }
}
