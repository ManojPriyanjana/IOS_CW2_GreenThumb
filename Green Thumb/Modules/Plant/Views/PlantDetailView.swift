import SwiftUI
import CoreData

struct PlantDetailView: View {
    @Environment(\.managedObjectContext) private var ctx

    let objectID: NSManagedObjectID
    @State private var plant: Plant?

    var body: some View {
        Group {
            if let plant {
                // Precompute strings (faster type-checking)
                let name      = plant.name ?? "Plant"
                let category  = plant.category ?? "Unknown"
                let planted   = plant.plantingDate?.formatted(date: .abbreviated, time: .omitted) ?? "—"
                let location  = (plant.location?.isEmpty == false) ? plant.location! : "—"
                let notes     = (plant.notes?.isEmpty == false) ? plant.notes! : "—"

                let taskCount   = (plant.tasks as? Set<CareTask>)?.count ?? 0
                let issueCount  = plant.healthIssues?.count ?? 0
                let schedCount  = plant.harvestSchedules?.count ?? 0

                List {
                    // Overview
                    Section("Overview") {
                        Text("Name: \(name)")
                        Text("Category: \(category)")
                        Text("Planted: \(planted)")
                        Text("Location: \(location)")
                        Text("Notes: \(notes)")
                    }

                    // Linked data
                    Section("Linked Data") {
                        // Tasks → use global list for now
                        NavigationLink("Tasks (\(taskCount))") {
                            AllTasksView()
                        }

                        // inside Section("Linked Data") in PlantDetailView
                        NavigationLink("Health Issues (\(issueCount))") {
                            HealthListView(plant: plant)   // ⬅ pass the Plant object
                        }


                        // Harvesting (placeholder until module is built)
                        NavigationLink("Harvesting (\(schedCount))") {
                            Text("Harvest screen placeholder")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                                .padding()
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .navigationTitle(name)
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Menu {
                            Button(role: .destructive) { deletePlant() } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            } else {
                // Loading view
                ProgressView()
                    .task { await load() }
            }
        }
    }

    // MARK: - Data

    private func load() async {
        do {
            let p = try ctx.existingObject(with: objectID) as? Plant
            await MainActor.run { self.plant = p }
        } catch {
            print("Fetch plant error:", error)
        }
    }

    private func deletePlant() {
        guard let plant else { return }
        ctx.delete(plant)
        do { try ctx.save() } catch { print("Delete error:", error) }
    }
}
