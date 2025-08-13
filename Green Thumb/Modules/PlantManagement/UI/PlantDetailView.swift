import SwiftUI

struct PlantDetailView: View {
    let plant: Plant
    let onEdit: (Plant) -> Void
    let onDelete: (UUID) -> Void
    let onMarkWatered: (Plant) -> Void

    var body: some View {
        List {
            Section("Overview") {
                LabeledContent("Name", value: plant.name)
                if !plant.species.isEmpty { LabeledContent("Species", value: plant.species) }
                if !plant.location.isEmpty { LabeledContent("Location", value: plant.location) }
            }

            Section("Care") {
                LabeledContent("Water every", value: "\(plant.wateringIntervalDays) days")
                LabeledContent("Last watered", value: plant.lastWatered.map { $0.formatted(date: .abbreviated, time: .omitted) } ?? "—")
                LabeledContent("Next water", value: plant.nextWaterDate.map { $0.formatted(date: .abbreviated, time: .omitted) } ?? "—")
            }

            if !plant.notes.isEmpty {
                Section("Notes") { Text(plant.notes) }
            }
        }
        .navigationTitle(plant.name)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button("Watered") { onMarkWatered(plant) }
                Button("Edit") { onEdit(plant) }
                Menu {
                    Button(role: .destructive) { onDelete(plant.id) } label: {
                        Label("Delete Plant", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }
}
