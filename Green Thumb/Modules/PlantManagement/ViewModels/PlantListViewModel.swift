import Foundation

@MainActor
final class PlantListViewModel: ObservableObject {
    @Published private(set) var plants: [Plant] = []
    @Published var searchText: String = ""
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let store: PlantStore

    init(store: PlantStore = InMemoryPlantStore(seed: [
        Plant(name: "Aloe Vera", species: "Aloe", location: "Balcony", lastWatered: .now.addingTimeInterval(-4*24*3600), wateringIntervalDays: 7),
        Plant(name: "Snake Plant", species: "Sansevieria", location: "Living Room", lastWatered: .now.addingTimeInterval(-10*24*3600), wateringIntervalDays: 14)
    ])) {
        self.store = store
        Task { await reload() }
    }

    var filteredPlants: [Plant] {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return plants }
        return plants.filter {
            [$0.name, $0.species, $0.location].joined(separator: " ")
                .localizedCaseInsensitiveContains(searchText)
        }
    }

    func reload() async {
        isLoading = true; defer { isLoading = false }
        do { plants = try await store.fetchAll() }
        catch { errorMessage = error.localizedDescription }
    }

    func delete(at offsets: IndexSet) {
        for index in offsets {
            let id = filteredPlants[index].id
            Task {
                do {
                    try await store.delete(id: id)
                    await reload()
                } catch { self.errorMessage = error.localizedDescription }
            }
        }
    }

    func save(_ plant: Plant) {
        Task {
            do {
                if plants.contains(where: { $0.id == plant.id }) {
                    try await store.update(plant)
                } else {
                    try await store.create(plant)
                }
                await reload()
            } catch { self.errorMessage = error.localizedDescription }
        }
    }
}
