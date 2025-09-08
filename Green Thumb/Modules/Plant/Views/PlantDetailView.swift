import SwiftUI
import CoreData

struct PlantDetailView: View {
    @Environment(\.managedObjectContext) private var ctx

    let objectID: NSManagedObjectID

    // 👇 Live fetch of the Plant by objectID
    @FetchRequest private var fetched: FetchedResults<Plant>

    init(objectID: NSManagedObjectID) {
        self.objectID = objectID
        _fetched = FetchRequest<Plant>(
            sortDescriptors: [],
            predicate: NSPredicate(format: "self == %@", objectID),
            animation: .default
        )
    }

    var body: some View {
        Group {
            if let plant = fetched.first {
                let name      = plant.name ?? "Plant"
                let category  = plant.category ?? "Unknown"
                let planted   = plant.plantingDate?.formatted(date: .abbreviated, time: .omitted) ?? "—"
                let location  = (plant.location?.isEmpty == false) ? plant.location! : "—"
                let notes     = (plant.notes?.isEmpty == false) ? plant.notes! : "—"

                // 👇 Count auto-updates because fetched plant is live
                let taskCount   = (plant.tasks as? Set<CareTask>)?.filter { $0.status != "Completed" }.count ?? 0
                let issueCount  = plant.healthIssues?.count ?? 0
                let schedCount  = plant.harvestSchedules?.count ?? 0

                List {
                    Section("Overview") {
                        Text("Name: \(name)")
                        Text("Category: \(category)")
                        Text("Planted: \(planted)")
                        Text("Location: \(location)")
                        Text("Notes: \(notes)")
                    }

                    Section("Linked Data") {
                        NavigationLink("Tasks (\(taskCount))") {
                            PlantTasksView(plant: plant)
                        }

                        NavigationLink("Health Issues (\(issueCount))") {
                            HealthListView(plant: plant)
                        }

                        NavigationLink("Harvesting (\(schedCount))") {
                            PlantHarvestingView(plant: plant)
                        }

                    }
                }
                .listStyle(.insetGrouped)
                .navigationTitle(name)
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Menu {
                            Button(role: .destructive) { deletePlant(plant) } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            } else {
                ProgressView()
            }
        }
    }

    // MARK: - Delete
    private func deletePlant(_ plant: Plant) {
        ctx.delete(plant)
        do { try ctx.save() } catch { print("Delete error:", error) }
    }
}
