import Foundation

// Provide plants from PlantManagement
public protocol HealthPlantSource {
    func allPlants() async throws -> [HealthPlant]
    func updateLastWatered(_ plantId: UUID, date: Date) async throws
    func updateLastFertilized(_ plantId: UUID, date: Date) async throws
}

// Provide recent care tasks from Task module (water/fertilize timestamps)
public protocol HealthTaskHistorySource {
    func lastWateredDate(for plantId: UUID) async throws -> Date?
    func lastFertilizedDate(for plantId: UUID) async throws -> Date?
}

// Provide current weather (bridge to your OpenWeather client)
public protocol HealthWeatherProvider {
    func currentWeather(lat: Double, lon: Double) async throws -> HealthWeather
}

// Provide last disease detection result for a plant
public protocol HealthDiseaseResultSource {
    func latestDiseaseSnapshot(for plantId: UUID) async throws -> HealthDiseaseSnapshot
}

// Persist health records locally (can swap to Core Data later)
public protocol HealthRecordStore {
    func save(_ record: PlantHealthRecord) throws
    func fetch(for plantId: UUID, limit: Int) throws -> [PlantHealthRecord]
}

// MARK: - Minimal in-memory defaults so it builds out-of-the-box

public final class InMemoryHealthRecordStore: HealthRecordStore {
    private var db: [UUID: [PlantHealthRecord]] = [:]
    public init() {}

    public func save(_ record: PlantHealthRecord) throws {
        db[record.plantId, default: []].insert(record, at: 0)
    }

    public func fetch(for plantId: UUID, limit: Int = 25) throws -> [PlantHealthRecord] {
        Array(db[plantId, default: []].prefix(limit))
    }
}

// Temporary stubs (replace with real adapters to your modules)
public final class DemoPlantSource: HealthPlantSource {
    public init() {}
    public func allPlants() async throws -> [HealthPlant] {
        [
            HealthPlant(id: UUID(), name: "Basil", species: "Ocimum basilicum", isOutdoor: false,
                        recommendedWaterEveryDays: 2, lastWatered: Calendar.current.date(byAdding: .day, value: -3, to: .now),
                        lastFertilized: Calendar.current.date(byAdding: .day, value: -30, to: .now)),
            HealthPlant(id: UUID(), name: "Rose", species: "Rosa", isOutdoor: true,
                        recommendedWaterEveryDays: 3, lastWatered: Calendar.current.date(byAdding: .day, value: -1, to: .now),
                        lastFertilized: Calendar.current.date(byAdding: .day, value: -50, to: .now), latitude: 6.9271, longitude: 79.8612)
        ]
    }
    public func updateLastWatered(_ plantId: UUID, date: Date) async throws {}
    public func updateLastFertilized(_ plantId: UUID, date: Date) async throws {}
}

public final class DemoTaskHistorySource: HealthTaskHistorySource {
    public init() {}
    public func lastWateredDate(for plantId: UUID) async throws -> Date? { Calendar.current.date(byAdding: .day, value: -2, to: .now) }
    public func lastFertilizedDate(for plantId: UUID) async throws -> Date? { Calendar.current.date(byAdding: .day, value: -45, to: .now) }
}

public final class DemoDiseaseResultSource: HealthDiseaseResultSource {
    public init() {}
    public func latestDiseaseSnapshot(for plantId: UUID) async throws -> HealthDiseaseSnapshot {
        .init(label: "Healthy", confidence: 0.72)
    }
}

// If you already have OpenWeather, create a small adapter to that later.
public final class DemoWeatherProvider: HealthWeatherProvider {
    public init() {}
    public func currentWeather(lat: Double, lon: Double) async throws -> HealthWeather {
        // Colombo-ish demo values
        return HealthWeather(tempC: 31, humidity: 75, condition: "Clouds")
    }
}
