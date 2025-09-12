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
                        NavigationLink(destination: PlantDetailView(objectID: plant.objectID)) {
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
            //--
        }
    }
}

// Local pill used only in this file to avoid cross-file dependency
private struct PrioritySelectPill: View {
    let title: String
    let color: Color
    let selected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(title)
                .font(.footnote)
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(selected ? color.opacity(0.2) : Color.gray.opacity(0.12))
                .foregroundStyle(selected ? color : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
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

    // New: Soil type and location list
    private let soilTypes = ["Loamy","Sandy","Clay","Silty","Peaty","Chalky","Custom"]
    @State private var soil = "Loamy"
    private let locations = ["Garden Bed","Greenhouse","Balcony","Indoor","Custom"]
    @State private var locationChoice = "Garden Bed"

    // Linked-data quick adds
    @State private var createdPlant: Plant? = nil
    @State private var showAddTask = false
    @State private var showAddHealth = false
    @State private var showAddHarvest = false

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
                    // Location dropdown with custom
                    Picker("Location", selection: $locationChoice) {
                        ForEach(locations, id: \.self) { Text($0) }
                    }
                    if locationChoice == "Custom" {
                        TextField("Custom location", text: $location)
                    }
                    // Soil type with custom stored in notes
                    Picker("Soil Type", selection: $soil) {
                        ForEach(soilTypes, id: \.self) { Text($0) }
                    }
                    if soil == "Custom" {
                        TextField("Custom soil type", text: $notes)
                    } else {
                        TextField("Notes (optional)", text: $notes, axis: .vertical)
                    }
                }

                Section("Linked Data") {
                    Button {
                        if let plant = ensurePlant() { createdPlant = plant; showAddTask = true }
                    } label: { Label("Add Task", systemImage: "checklist") }

                    Button {
                        if let plant = ensurePlant() { createdPlant = plant; showAddHealth = true }
                    } label: { Label("Add Health Issue", systemImage: "heart.text.square") }

                    Button {
                        if let plant = ensurePlant() { createdPlant = plant; showAddHarvest = true }
                    } label: { Label("Add Harvest Schedule", systemImage: "basket.fill") }
                }
            }
            .navigationTitle("Add Plant")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { _ = ensurePlant(); UIImpactFeedbackGenerator(style: .light).impactOccurred(); dismiss() }.disabled(name.trimmingCharacters(in: .whitespaces).isEmpty) }
            }
            .sheet(isPresented: $showPhotoPicker) {
                ImagePicker(image: $photo)
            }
            // Present linked-data sheets using the newly created plant
            .sheet(isPresented: $showAddTask) {
                if let p = createdPlant { AddGlobalTaskSheet(fixedPlant: p) }
            }
            .sheet(isPresented: $showAddHealth) {
                if let p = createdPlant { AddHealthIssueSheet(plant: p) }
            }
            .sheet(isPresented: $showAddHarvest) {
                if let p = createdPlant { NavigationStack { AddEditHarvestScheduleView(plant: p) } }
            }
        }
    }

    // Create plant if not created yet, returns the plant instance
    private func ensurePlant() -> Plant? {
        if let createdPlant { return createdPlant }
        let repo = PlantRepository(ctx: ctx)
        do {
            // Compose notes with soil when provided
            let soilNotePrefix = soil == "Custom" ? "Soil: \(notes)" : "Soil: \(soil)"
            let combinedNotes = [soilNotePrefix, notes].filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }.joined(separator: "\n")

            let loc = locationChoice == "Custom" ? (location.isEmpty ? nil : location) : locationChoice
            let plant = try repo.createAndReturn(
                name: name,
                category: category,
                plantingDate: plantingDate,
                location: loc,
                photoData: photo?.jpegData(compressionQuality: 0.85),
                notes: combinedNotes.isEmpty ? nil : combinedNotes
            )
            createdPlant = plant
            return plant
        } catch {
            print("Save error:", error)
            return nil
        }
    }
}
