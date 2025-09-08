import SwiftUI
import CoreData

struct HarvestScheduleDetailView: View {
    @Environment(\.managedObjectContext) private var ctx
    @ObservedObject var schedule: HarvestSchedule

    @State private var showEdit = false
    @State private var showLog  = false

    // Logs live fetch
    @FetchRequest private var logs: FetchedResults<HarvestLog>

    init(schedule: HarvestSchedule) {
        self.schedule = schedule
        _logs = FetchRequest<HarvestLog>(
            sortDescriptors: [NSSortDescriptor(key: "actualDate", ascending: false)],
            predicate: NSPredicate(format: "schedule == %@", schedule),
            animation: .default
        )
    }

    var totalYield: String {
        let sum = logs.reduce(0.0) { $0 + ($1.quantity) }
        let unit = logs.first?.unit ?? ""
        return sum > 0 ? "\(sum.clean) \(unit)" : "—"
    }

    var body: some View {
        List {
            Section("Overview") {
                HStack {
                    Label("Plant", systemImage: "leaf")
                    Spacer()
                    Text(schedule.plant?.name ?? "Plant").foregroundStyle(.secondary)
                }
                HStack {
                    Label("Status", systemImage: "circlebadge")
                    Spacer()
                    StatusChip(status: HarvestRepository.computeStatus(for: schedule))
                }
                HStack {
                    Label("Target", systemImage: "calendar")
                    Spacer()
                    Text(schedule.expectedStart?.formatted(date: .abbreviated, time: .omitted) ?? "—")
                        .foregroundStyle(.secondary)
                }
                if let end = schedule.expectedEnd {
                    HStack {
                        Label("Window End", systemImage: "calendar.badge.clock")
                        Spacer()
                        Text(end.formatted(date: .abbreviated, time: .omitted)).foregroundStyle(.secondary)
                    }
                }
                if let notes = schedule.notes, !notes.isEmpty {
                    Text(notes).font(.body)
                }
            }

            Section("Harvest Logs") {
                if logs.isEmpty {
                    Text("No logs yet").foregroundStyle(.secondary)
                } else {
                    ForEach(logs) { log in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(log.actualDate?.formatted(date: .abbreviated, time: .omitted) ?? "—")
                                .font(.headline)
                            Text("Quantity: \(log.quantity.clean) \(log.unit ?? "")")
                            if let q = log.quality, !q.isEmpty {
                                Text("Quality: \(q)")
                            }
                            if let n = log.notes, !n.isEmpty {
                                Text(n).foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .onDelete { idx in
                        idx.map { logs[$0] }.forEach { l in
                            try? HarvestRepository.deleteLog(l, in: ctx)
                        }
                    }
                }
            }

            Section("Analytics") {
                HStack {
                    Text("Total yield")
                    Spacer()
                    Text(totalYield).foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Schedule")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    showLog = true
                } label: {
                    Label("Log Harvest", systemImage: "square.and.pencil")
                }

                Menu {
                    Button {
                        showEdit = true
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }

                    Button(role: .destructive) {
                        do {
                            try HarvestRepository.deleteSchedule(schedule, in: ctx)
                        } catch {
                            print("Delete schedule error:", error)
                        }
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: { Image(systemName: "ellipsis.circle") }
            }
        }
        .sheet(isPresented: $showEdit) {
            NavigationStack { AddEditHarvestScheduleView(schedule: schedule) }
        }
        .sheet(isPresented: $showLog) {
            NavigationStack { LogHarvestView(schedule: schedule) }
        }
        .onAppear {
            HarvestRepository.refreshStatus(schedule, in: ctx)
        }
    }
}
