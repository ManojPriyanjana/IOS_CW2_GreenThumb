import SwiftUI
import CoreData

struct PlantHarvestingView: View {
    @Environment(\.managedObjectContext) private var ctx
    let plant: Plant

    @State private var showAdd = false

    // Live fetch scoped to this plant
    @FetchRequest private var schedules: FetchedResults<HarvestSchedule>

    init(plant: Plant) {
        self.plant = plant
        _schedules = FetchRequest<HarvestSchedule>(
            sortDescriptors: [NSSortDescriptor(key: "expectedStart", ascending: true)],
            predicate: NSPredicate(format: "plant == %@", plant),
            animation: .default
        )
    }

    var body: some View {
        List {
            if schedules.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "leaf")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("No harvest schedules yet")
                        .foregroundStyle(.secondary)
                    Text("Tap the + button to add your first schedule.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                ForEach(schedules) { schedule in
                    NavigationLink {
                        HarvestScheduleDetailView(schedule: schedule)
                    } label: {
                        ScheduleRowView(schedule: schedule)
                    }
                }
                .onDelete { idx in
                    idx.map { schedules[$0] }.forEach { s in
                        try? HarvestRepository.deleteSchedule(s, in: ctx)
                    }
                }
            }
        }
        .navigationTitle("Harvesting")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showAdd = true
                } label: { Image(systemName: "plus") }
                .tint(.green)
            }
        }
        .sheet(isPresented: $showAdd) {
            NavigationStack {
                AddEditHarvestScheduleView(plant: plant)
            }
        }
    }
}
