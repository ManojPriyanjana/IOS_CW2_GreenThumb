import SwiftUI
import CoreData

struct HarvestListView: View {
    @Environment(\.managedObjectContext) private var ctx
    @State private var selectedDate = Date()
    @State private var showingAdd = false

    // Fetch only plants that have harvest tracking enabled
    @FetchRequest(
        entity: Plant.entity(),
        sortDescriptors: [NSSortDescriptor(key: "dateAdded", ascending: false)],
        predicate: NSPredicate(format: "maturityMinDays > 0 AND maturityMaxDays > 0")
    )
    private var plants: FetchedResults<Plant>

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGreen).opacity(0.12).ignoresSafeArea()

                VStack(spacing: 12) {
                    header
                    WeekStrip(selected: $selectedDate)

                    if plants.isEmpty {
                        emptyState
                    } else {
                        listContent
                    }
                }
            }
            .sheet(isPresented: $showingAdd) {
                AddHarvestSheet()
                    .environment(\.managedObjectContext, ctx)
            }
        }
    }

    // Header

    private var header: some View {
        HStack {
            Image(systemName: "chevron.left")
                .opacity(0) // placeholder if no back
                .frame(width: 44, height: 44)

            Spacer()

            Text("Harvest")
                .font(.title2).bold()

            Spacer()

            Button {
                showingAdd = true
            } label: {
                Image(systemName: "plus").font(.headline)
            }
            .frame(width: 44, height: 44)
        }
        .padding(.horizontal)
    }

    // Empty State

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "leaf.circle")
                .font(.system(size: 48))
                .foregroundStyle(.green)
            Text("No harvests yet")
                .font(.headline)
            Text("Tap + to enable harvest tracking for a plant.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 40)
    }

    // List

    private var listContent: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(plants, id: \.objectID) { plant in
                    HarvestRowView(plant: plant)
                        .padding(.horizontal)
                        .contextMenu {
                            // button initializers
                            Button("Mark harvested") {
                                plant.lastHarvested = Date()
                                try? ctx.save()
                            }
                            Button("Disable harvest", role: .destructive) {
                                plant.maturityMinDays = 0
                                plant.maturityMaxDays = 0
                                try? ctx.save()
                            }
                        }
                }
            }
            .padding(.bottom, 24)
        }
    }
}
