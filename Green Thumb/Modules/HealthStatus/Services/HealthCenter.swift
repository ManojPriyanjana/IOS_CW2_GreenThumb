import Foundation

@MainActor
public final class HealthCenter: ObservableObject {
    private let plants: HealthPlantSource
    private let tasks: HealthTaskHistorySource
    private let diseases: HealthDiseaseResultSource
    private let weather: HealthWeatherProvider?
    private let store: HealthRecordStore
    private let engine = HealthEngine()

    @Published public private(set) var items: [HealthItem] = []
    @Published public var isLoading = false
    @Published public var error: String?

    public struct HealthItem: Identifiable {
        public let id = UUID()
        public let plant: HealthPlant
        public let record: PlantHealthRecord
    }

    public init(plants: HealthPlantSource,
                tasks: HealthTaskHistorySource,
                diseases: HealthDiseaseResultSource,
                weather: HealthWeatherProvider?,
                store: HealthRecordStore) {
        self.plants = plants
        self.tasks = tasks
        self.diseases = diseases
        self.weather = weather
        self.store = store
    }

    public func refresh() async {
        error = nil
        isLoading = true
        do {
            let all = try await plants.allPlants()
            var next: [HealthItem] = []

            for p in all {
                let lastWater = try await tasks.lastWateredDate(for: p.id) ?? p.lastWatered
                let lastFert  = try await tasks.lastFertilizedDate(for: p.id) ?? p.lastFertilized
                let disease   = try await diseases.latestDiseaseSnapshot(for: p.id)

                var w: HealthWeather? = nil
                if let lat = p.latitude, let lon = p.longitude {
                    w = try await weather?.currentWeather(lat: lat, lon: lon)
                }

                let result = engine.computeScore(for: p, weather: w, manual: nil, disease: disease,
                                                 taskOverrides: (lastWatered: lastWater, lastFertilized: lastFert))

                let record = PlantHealthRecord(plantId: p.id, date: Date.now, score: result.score, status: result.status, factors: result.factors, note: nil)
                try store.save(record)
                next.append(.init(plant: p, record: record))
            }

            self.items = next.sorted { $0.record.score > $1.record.score }
        } catch { self.error = error.localizedDescription }
        isLoading = false
    }

    public func addManualCheck(for plant: HealthPlant, manual: HealthManualCheck) {
        // Reuse last computed factors/weather if you want; for now compute with manual only
        let result = engine.computeScore(for: plant, weather: nil, manual: manual, disease: nil)
        let record = PlantHealthRecord(plantId: plant.id, date: Date.now, score: result.score, status: result.status, factors: result.factors, note: manual.note)
        try? store.save(record)
        Task { await refresh() }
    }

    public func history(for plantId: UUID, limit: Int = 25) -> [PlantHealthRecord] {
        (try? store.fetch(for: plantId, limit: limit)) ?? []
    }
}
