import Foundation

public struct Plant: Identifiable, Equatable, Hashable, Codable {
    public let id: UUID
    public var name: String
    public var species: String
    public var location: String
    public var lastWatered: Date?
    public var wateringIntervalDays: Int
    public var notes: String

    public init(
        id: UUID = UUID(),
        name: String,
        species: String = "",
        location: String = "",
        lastWatered: Date? = nil,
        wateringIntervalDays: Int = 7,
        notes: String = ""
    ) {
        self.id = id
        self.name = name
        self.species = species
        self.location = location
        self.lastWatered = lastWatered
        self.wateringIntervalDays = max(1, wateringIntervalDays)
        self.notes = notes
    }

    public var nextWaterDate: Date? {
        guard let last = lastWatered else { return nil }
        return Calendar.current.date(byAdding: .day, value: wateringIntervalDays, to: last)
    }

    public var isWateringDue: Bool {
        guard let next = nextWaterDate else { return true }
        return next <= Date()
    }
}
