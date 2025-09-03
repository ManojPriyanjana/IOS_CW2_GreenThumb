import SwiftUI
import CoreData

struct PlantDetailView: View {
    @Environment(\.managedObjectContext) private var ctx
    let objectID: NSManagedObjectID
    @State private var plant: Plant?

    var body: some View {
        Group {
            if let plant {
                // Precompute strings so the view is simple to type-check
                let name = plant.name ?? "Plant"
                let category = plant.category ?? "Unknown"
                let planted = plant.plantingDate?.formatted(date: .abbreviated, time: .omitted) ?? "—"
                let location = (plant.location?.isEmpty == false) ? plant.location! : "—"
                let notes = (plant.notes?.isEmpty == false) ? plant.notes! : "—"
                let taskCount = plant.tasks?.count ?? 0
                let issueCount = plant.healthIssues?.count ?? 0
                let schedCount = plant.harvestSchedules?.count ?? 0

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
                            Text("Tasks screen placeholder")
                        }
                        NavigationLink("Health Issues (\(issueCount))") {
                            Text("Health screen placeholder")
                        }
                        NavigationLink("Harvesting (\(schedCount))") {
                            Text("Harvest screen placeholder")
                        }
                    }
                }
                .navigationTitle(name)
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Menu {
                            Button("Delete", role: .destructive) { deletePlant() }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            } else {
                ProgressView().task { await load() }
            }
        }
    }


    private func load() async {
        do {
            let p = try ctx.existingObject(with: objectID) as? Plant
            await MainActor.run { self.plant = p }
        } catch { print("Fetch plant error:", error) }
    }

    private func deletePlant() {
        guard let plant else { return }
        do { ctx.delete(plant); try ctx.save() } catch { print("Delete error:", error) }
    }
}
