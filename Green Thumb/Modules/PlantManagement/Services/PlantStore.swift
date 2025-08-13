import Foundation

// MARK: - Abstraction (easy to replace with Core Data later)
public protocol PlantStore: AnyObject {
    func fetchAll() async throws -> [Plant]
    func create(_ plant: Plant) async throws
    func update(_ plant: Plant) async throws
    func delete(id: UUID) async throws
}

// MARK: - In-memory implementation (MVP / tests)
public final class InMemoryPlantStore: PlantStore {
    private var plants: [UUID: Plant] = [:]

    public init(seed: [Plant] = []) {
        seed.forEach { plants[$0.id] = $0 }
    }

    public func fetchAll() async throws -> [Plant] {
        Array(plants.values).sorted(by: { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending })
    }

    public func create(_ plant: Plant) async throws { plants[plant.id] = plant }

    public func update(_ plant: Plant) async throws { plants[plant.id] = plant }

    public func delete(id: UUID) async throws { plants[id] = nil }
}
