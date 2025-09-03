import SwiftUI
import CoreData

struct PlantListView: View {
    @Environment(\.managedObjectContext) private var ctx
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Plant.plantingDate, ascending: true)],
        animation: .default
    ) private var plants: FetchedResults<Plant>

    @State private var showingAdd = false

    var body: some View {
        NavigationStack {
            Group {
                if plants.isEmpty {
                    ContentUnavailableView("No plants yet",
                                           systemImage: "leaf",
                                           description: Text("Tap Add to register your first plant."))
                } else {
                    List(plants) { plant in
                        NavigationLink(value: plant.objectID) {
                            HStack(spacing: 12) {
                                if let data = plant.photoData, let ui = UIImage(data: data) {
                                    Image(uiImage: ui).resizable().scaledToFill()
                                        .frame(width: 44, height: 44).clipShape(RoundedRectangle(cornerRadius: 8))
                                } else {
                                    Image(systemName: "leaf").frame(width: 44, height: 44)
                                }
                                VStack(alignment: .leading) {
                                    Text(plant.name ?? "Unnamed").font(.headline)
                                    Text(plant.category ?? "Unknown").font(.subheadline).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            //--
            .navigationTitle("My Plants")
            .toolbar(content: {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingAdd = true }) {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add plant")
                }
            })
            .sheet(isPresented: $showingAdd, content: {
                AddPlantSheet()
            })
            .navigationDestination(for: NSManagedObjectID.self) { objectID in
                PlantDetailView(objectID: objectID)
            }
            //--
        }
    }
}

private struct AddPlantSheet: View {
    @Environment(\.managedObjectContext) private var ctx
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var category = "Vegetables"
    @State private var plantingDate = Date()
    @State private var location = ""
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Basic") {
                    TextField("Name", text: $name)
                    Picker("Category", selection: $category) {
                        ForEach(["Herbs","Vegetables","Flowers","Custom"], id: \.self) { Text($0) }
                    }
                    DatePicker("Planting Date", selection: $plantingDate, displayedComponents: .date)
                    TextField("Location (optional)", text: $location)
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                }
            }
            .navigationTitle("Add Plant")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() }.disabled(name.trimmingCharacters(in: .whitespaces).isEmpty) }
            }
        }
    }

    private func save() {
        let repo = PlantRepository(ctx: ctx)
        do {
            try repo.create(
                name: name,
                category: category,
                plantingDate: plantingDate,
                location: location.isEmpty ? nil : location,
                photoData: nil,
                notes: notes.isEmpty ? nil : notes
            )
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            dismiss()
        } catch {
            print("Save error:", error)
        }
    }
}
