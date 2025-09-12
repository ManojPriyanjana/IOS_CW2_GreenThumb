import SwiftUI
import CoreData

struct PlantListView: View {
    @Environment(\.managedObjectContext) private var ctx
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Plant.plantingDate, ascending: true)],
        animation: .default
    ) private var plants: FetchedResults<Plant>

    // Search
    @State private var query = ""
    @State private var showingAdd = false

    // Filtered results including search by name or UUID (plant id)
    private var filtered: [Plant] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return Array(plants) }
        let lower = q.lowercased()
        // remove hyphens to allow short id lookups like prefix of UUID
        let compact = lower.replacingOccurrences(of: "-", with: "")
        return plants.filter { p in
            let name = (p.name ?? "").lowercased()
            if name.contains(lower) { return true }
            if let uuid = p.id?.uuidString.lowercased() {
                let uuidCompact = uuid.replacingOccurrences(of: "-", with: "")
                return uuid.contains(lower) || uuidCompact.contains(compact)
            }
            return false
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if plants.isEmpty {
                    ContentUnavailableView("No plants yet",
                                           systemImage: "leaf",
                                           description: Text("Tap Add to register your first plant."))
                } else if filtered.isEmpty {
                    ContentUnavailableView("No results",
                                           systemImage: "magnifyingglass",
                                           description: Text("Try a different name or plant ID."))
                } else {
                    List(filtered, id: \.objectID) { plant in
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
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .automatic), prompt: "Search by name or ID")
            .autocorrectionDisabled(true)
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
    @State private var photo: UIImage? = nil
    @State private var showPhotoPicker = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Photo") {
                    HStack(spacing: 12) {
                        Group {
                            if let img = photo {
                                Image(uiImage: img)
                                    .resizable().scaledToFill()
                                    .frame(width: 64, height: 64)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(.quaternary))
                            } else {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.secondary.opacity(0.08))
                                        .frame(width: 64, height: 64)
                                    Image(systemName: "photo")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        Button(photo == nil ? "Add Photo" : "Change Photo") { showPhotoPicker = true }
                    }
                }
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
            .sheet(isPresented: $showPhotoPicker) {
                ImagePicker(image: $photo)
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
                photoData: photo?.jpegData(compressionQuality: 0.85),
                notes: notes.isEmpty ? nil : notes
            )
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            dismiss()
        } catch {
            print("Save error:", error)
        }
    }
}
