import SwiftUI
import CoreData

struct MyGardenView: View {
    @Environment(\.managedObjectContext) private var ctx
    @FetchRequest(entity: Plant.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \Plant.dateAdded, ascending: false)])
    private var plants: FetchedResults<Plant>

    @State private var searchText = ""
    @State private var filterLight: LightLevel? = nil
    @State private var layoutGrid = true
    @State private var showAdd = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                // Stats row
                HStack {
                    statBlock(title: "Plants", value: "\(plants.count)")
                    statBlock(title: "Locations", value: "\(Set(plants.compactMap{$0.location}).count)")
                    statBlock(title: "Healthy", value: "\(Int(healthyRatio*100))%")
                }.padding(.horizontal)

                // Search + filter row
                HStack {
                    TextField("Search plants…", text: $searchText)
                        .textFieldStyle(.roundedBorder)
                    Button {
                        layoutGrid.toggle()
                    } label: { Image(systemName: layoutGrid ? "square.grid.2x2" : "list.bullet") }
                        .padding(.leading, 6)
                }.padding(.horizontal)

                ScrollView {
                    LazyVGrid(columns: layoutGrid ? [GridItem(.adaptive(minimum: 150), spacing: 12)] : [GridItem(.flexible())], spacing: 12) {
                        ForEach(filteredPlants, id: \.id) { plant in
                            NavigationLink {
                                PlantDetailView(plant: plant)
                            } label: {
                                PlantCardView(plant: plant, compact: !layoutGrid)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 4)
                }
            }
            .navigationTitle("My Garden")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Picker("Light", selection: Binding(get: { filterLight }, set: { filterLight = $0 })) {
                            Text("All Lights").tag(LightLevel?.none)
                            ForEach(LightLevel.allCases) { Text($0.rawValue.capitalized).tag(LightLevel?.some($0)) }
                        }
                        Button("Clear Filters") { filterLight = nil }
                    } label: { Label("Filter", systemImage: "line.3.horizontal.decrease.circle") }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAdd = true } label: { Label("Add", systemImage: "plus") }
                }
            }
            .sheet(isPresented: $showAdd) { AddPlantFlowView() }
        }
    }

    private var filteredPlants: [Plant] {
        plants.filter { p in
            let matchSearch = searchText.isEmpty || (p.commonName ?? "").localizedCaseInsensitiveContains(searchText) || (p.location ?? "").localizedCaseInsensitiveContains(searchText)
            let matchLight = filterLight == nil || p.lightLevel == filterLight?.rawValue
            return matchSearch && matchLight
        }
    }

    private var healthyRatio: Double {
        guard plants.count > 0 else { return 1 }
        let healthy = plants.filter { $0.healthStatus == HealthStatus.healthy.rawValue }.count
        return Double(healthy) / Double(plants.count)
    }

    private func statBlock(title: String, value: String) -> some View {
        VStack {
            Text(value).font(.title2).bold()
            Text(title).font(.caption).foregroundColor(AppTheme.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.gray.opacity(0.08)))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("\(title) \(value)"))
    }
}

struct PlantCardView: View {
    @ObservedObject var plant: Plant
    var compact: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let data = plant.photo, let ui = UIImage(data: data) {
                Image(uiImage: ui).resizable().scaledToFill()
                    .frame(height: compact ? 80 : 120).clipped()
                    .cornerRadius(10)
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 10).fill(.gray.opacity(0.15))
                    Text("Photo").foregroundColor(AppTheme.muted)
                }
                .frame(height: compact ? 80 : 120)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(plant.commonName ?? "Plant").font(.headline)
                if let loc = plant.location, !loc.isEmpty {
                    Label(loc, systemImage: "mappin.circle").font(.caption).foregroundColor(AppTheme.muted)
                }
                HStack(spacing: 12) {
                    Label(nextWateringText(for: plant), systemImage: "drop.fill").font(.caption2)
                    Label(nextFertilizeText(for: plant), systemImage: "leaf").font(.caption2)
                }.foregroundColor(AppTheme.muted)
            }
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.gray.opacity(0.08)))
        .accessibilityElement(children: .combine)
    }

    private func nextWateringText(for p: Plant) -> String {
        let last = p.lastWatered ?? p.dateAdded ?? Date()
        let next = Calendar.current.date(byAdding: .day, value: Int(p.wateringFreqDays), to: last) ?? Date()
        return "Water \(relative(next))"
    }

    private func nextFertilizeText(for p: Plant) -> String {
        let last = p.lastFertilized ?? p.dateAdded ?? Date()
        let next = Calendar.current.date(byAdding: .day, value: Int(p.fertilizeFreqDays), to: last) ?? Date()
        return "Fertilize \(relative(next))"
    }

    private func relative(_ date: Date) -> String {
        let fmt = RelativeDateTimeFormatter(); fmt.unitsStyle = .abbreviated
        return fmt.localizedString(for: date, relativeTo: Date())
    }
}
