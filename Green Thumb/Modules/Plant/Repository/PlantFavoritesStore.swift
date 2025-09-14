import Foundation
import CoreData

/// Lightweight favorites store for plants using UserDefaults.
/// Stores NSManagedObjectID URI strings so it doesn't require Core Data model changes.
struct PlantFavoritesStore {
    private let key = "plantFavorites.v1"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> Set<String> {
        let arr = defaults.stringArray(forKey: key) ?? []
        return Set(arr)
    }

    func save(_ set: Set<String>) {
        defaults.set(Array(set), forKey: key)
    }

    func contains(_ plant: Plant) -> Bool {
        contains(idURI(for: plant))
    }

    func contains(_ idURI: String) -> Bool {
        load().contains(idURI)
    }

    func add(_ plant: Plant) {
        add(idURI(for: plant))
    }

    func add(_ idURI: String) {
        var s = load()
        s.insert(idURI)
        save(s)
    }

    func remove(_ plant: Plant) {
        remove(idURI(for: plant))
    }

    func remove(_ idURI: String) {
        var s = load()
        s.remove(idURI)
        save(s)
    }

    func idURI(for plant: Plant) -> String {
        plant.objectID.uriRepresentation().absoluteString
    }
}
