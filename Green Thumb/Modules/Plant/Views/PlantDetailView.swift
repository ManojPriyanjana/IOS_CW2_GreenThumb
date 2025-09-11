import SwiftUI
import CoreData

struct PlantDetailView: View {
    @Environment(\.managedObjectContext) private var ctx

    let objectID: NSManagedObjectID

    // 👇 Live fetch of the Plant by objectID
    @FetchRequest private var fetched: FetchedResults<Plant>
    @State private var showEdit = false

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
                    if let data = plant.photoData, let ui = UIImage(data: data) {
                        Image(uiImage: ui)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity, minHeight: 200, maxHeight: 240)
                            .clipped()
                            .listRowInsets(EdgeInsets())
                            .listRowSeparator(.hidden)
                            .accessibilityLabel("Plant photo")
                    }
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
                            Button { showEdit = true } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            Button(role: .destructive) { deletePlant(plant) } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
                .sheet(isPresented: $showEdit) {
                    EditPlantSheet(plant: plant)
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

// MARK: - Edit plant

private struct EditPlantSheet: View {
    @Environment(\.managedObjectContext) private var ctx
    @Environment(\.dismiss) private var dismiss

    @ObservedObject var plant: Plant

    @State private var name: String = ""
    @State private var category: String = "Vegetables"
    @State private var plantingDate: Date = Date()
    @State private var location: String = ""
    @State private var notes: String = ""
    @State private var photo: UIImage? = nil
    @State private var showPhotoPicker = false

    private let categories = ["Herbs","Vegetables","Flowers","Custom"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Photo") {
                    HStack(spacing: 12) {
                        Group {
                            if let img = photo {
                                Image(uiImage: img)
                                    .resizable().scaledToFill()
                                    .frame(width: 72, height: 72)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(.quaternary))
                            } else {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.secondary.opacity(0.08))
                                        .frame(width: 72, height: 72)
                                    Image(systemName: "photo")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        VStack(alignment: .leading, spacing: 8) {
                            Button(photo == nil ? "Add Photo" : "Change Photo") { showPhotoPicker = true }
                            if photo != nil {
                                Button("Remove Photo", role: .destructive) { photo = nil }
                            }
                        }
                    }
                }

                Section("Basic") {
                    TextField("Name", text: $name)
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { Text($0) }
                    }
                    DatePicker("Planting Date", selection: $plantingDate, displayedComponents: .date)
                    TextField("Location (optional)", text: $location)
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                }
            }
            .navigationTitle("Edit Plant")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .sheet(isPresented: $showPhotoPicker) { ImagePicker(image: $photo) }
            .onAppear(perform: load)
        }
    }

    private func load() {
        name = plant.name ?? ""
        category = plant.category ?? categories[1]
        plantingDate = plant.plantingDate ?? Date()
        location = plant.location ?? ""
        notes = plant.notes ?? ""
        if let data = plant.photoData, let ui = UIImage(data: data) { photo = ui } else { photo = nil }
    }

    private func save() {
        plant.name = name
        plant.category = category
        plant.plantingDate = plantingDate
        plant.location = location.trimmingCharacters(in: .whitespaces).isEmpty ? nil : location
        plant.notes = notes.trimmingCharacters(in: .whitespaces).isEmpty ? nil : notes
        plant.photoData = photo?.jpegData(compressionQuality: 0.85)
        do { try ctx.save(); dismiss() } catch { print("Save error:", error) }
    }
}
