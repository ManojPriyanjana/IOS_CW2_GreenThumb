import SwiftUI

struct PlantListView: View {
    @StateObject private var vm = PlantListViewModel()
    @State private var showingAdd = false
    @State private var editingPlant: Plant?

    var body: some View {
        NavigationStack {
            Group {
                if vm.isLoading && vm.plants.isEmpty {
                    ProgressView("Loading plants…")
                } else if vm.filteredPlants.isEmpty {
                    ContentUnavailableView(
                        "No plants yet",
                        systemImage: "leaf",
                        description: Text("Add your first plant to track watering schedules and notes.")
                    )
                } else {
                    List {
                        ForEach(vm.filteredPlants) { plant in
                            NavigationLink {
                                PlantDetailView(
                                    plant: plant,
                                    onEdit: { editingPlant = $0 },
                                    onDelete: { id in vm.delete(at: IndexSet(integer: vm.filteredPlants.firstIndex(where: { $0.id == id })!)) },
                                    onMarkWatered: { p in
                                        var updated = p
                                        updated.lastWatered = Date()
                                        vm.save(updated)
                                    }
                                )
                            } label: {
                                PlantRow(plant: plant)
                            }
                        }
                        .onDelete(perform: vm.delete)
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("My Plants")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAdd = true
                    } label: { Image(systemName: "plus") }
                    .accessibilityLabel("Add Plant")
                }
            }
            .searchable(text: $vm.searchText, placement: .navigationBarDrawer(displayMode: .automatic), prompt: "Search plants")
            .sheet(isPresented: $showingAdd) {
                NavigationStack {
                    AddEditPlantView { newPlant in
                        vm.save(newPlant)
                    }
                }
            }
            .sheet(item: $editingPlant) { plant in
                NavigationStack {
                    AddEditPlantView(existing: plant) { updated in
                        vm.save(updated)
                    }
                }
            }
            .alert("Error", isPresented: Binding(get: { vm.errorMessage != nil }, set: { _ in vm.errorMessage = nil })) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(vm.errorMessage ?? "")
            }
        }
    }
}
