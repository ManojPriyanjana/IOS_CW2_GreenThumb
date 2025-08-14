import SwiftUI
import CoreData

struct PlantDetailView: View {
    @ObservedObject var plant: Plant
    @Environment(\.managedObjectContext) private var ctx

    // MARK: - Derived data

    private var tasksSorted: [CareTask] {
        (plant.tasks?.allObjects as? [CareTask] ?? [])
            .sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
    }

    // MARK: - View

    var body: some View {
        ScrollView {
            HeaderImage(data: plant.photo)

            VStack(alignment: .leading, spacing: 16) {
                titleRow

                InfoGrid(plant: plant)

                Text("Care Schedule")
                    .font(.title3).bold()

                VStack(spacing: 10) {
                    ForEach(tasksSorted, id: \.id) { task in
                        CareRow(task: task, completeAction: { complete(task: task) })
                    }
                    if tasksSorted.isEmpty {
                        Text("No care tasks yet.")
                            .foregroundColor(.secondary)
                            .font(.footnote)
                    }
                }

                Text("Tasks & Health Log")
                    .font(.title3).bold()

                HealthLogList(plant: plant)

                ActionBar(addWater: addWateredNow,
                          addHealth: addHealthLog,
                          addPhoto: addPhoto)
            }
            .padding()
        }
        .navigationTitle(plant.commonName ?? "Plant")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Pieces

    private var titleRow: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                Text(plant.commonName ?? "Plant")
                    .font(.title2).bold()
                if let sci = plant.scientificName, !sci.isEmpty {
                    Text(sci)
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                }
            }
            Spacer()
            StatusPill(statusRaw: plant.healthStatus ?? HealthStatus.healthy.rawValue)
        }
    }

    // MARK: - Actions

    private func complete(task: CareTask) {
        task.isCompleted = true
        task.completedDate = Date()

        // Auto-create next cadence task for water/fertilize
        if let type = task.type {
            let next = CareTask(context: ctx)
            next.id = UUID()
            next.type = type
            next.isCompleted = false
            next.plant = plant

            let days: Int
            if type == CareType.water.rawValue {
                days = Int(plant.wateringFreqDays)
                plant.lastWatered = Date()
            } else if type == CareType.fertilize.rawValue {
                days = Int(plant.fertilizeFreqDays)
                plant.lastFertilized = Date()
            } else {
                days = 30
            }

            next.dueDate = Calendar.current.date(byAdding: .day, value: max(days, 1), to: Date())
        }

        try? ctx.save()
    }

    private func addWateredNow() {
        plant.lastWatered = Date()

        let log = HealthLog(context: ctx)
        log.id = UUID()
        log.date = Date()
        log.note = "Watered plant."
        log.statusScore = 90
        log.plant = plant

        try? ctx.save()
    }

    private func addHealthLog() {
        let log = HealthLog(context: ctx)
        log.id = UUID()
        log.date = Date()
        log.note = "Health check: looks good."
        log.statusScore = 85
        log.plant = plant

        try? ctx.save()
    }

    private func addPhoto() {
        // Hook up to your Photo picker / DiseaseDetection module if desired.
    }
}

// MARK: - Subviews

private struct HeaderImage: View {
    let data: Data?

    var body: some View {
        ZStack(alignment: .topTrailing) {
            if let data, let ui = UIImage(data: data) {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 220)
                    .clipped()
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 220)
                    .overlay(Text("Plant Photo").foregroundColor(.secondary))
            }

            Image(systemName: "camera.fill")
                .padding(8)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
                .padding()
                .accessibilityHidden(true)
        }
    }
}

private struct StatusPill: View {
    let statusRaw: String

    var body: some View {
        let bg: Color = {
            switch statusRaw {
            case HealthStatus.attention.rawValue: return .orange.opacity(0.15)
            case HealthStatus.sick.rawValue: return .red.opacity(0.15)
            default: return Color.green.opacity(0.15)
            }
        }()

        return Text(statusRaw.capitalized)
            .font(.caption)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(bg)
            .clipShape(Capsule())
            .accessibilityLabel(Text("Health status \(statusRaw)"))
    }
}

private struct InfoGrid: View {
    @ObservedObject var plant: Plant

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()),
                            GridItem(.flexible())],
                  spacing: 12) {
            InfoTile(title: "Location",
                     value: plant.location?.isEmpty == false ? plant.location! : "—",
                     systemImage: "mappin.and.ellipse")

            InfoTile(title: "Pot Size",
                     value: "\(Int(plant.potSizeCM)) cm",
                     systemImage: "leaf")

            InfoTile(title: "Added",
                     value: plant.dateAdded?.formatted(date: .abbreviated, time: .omitted) ?? "—",
                     systemImage: "calendar")

            InfoTile(title: "Light",
                     value: (plant.lightLevel ?? "").capitalized,
                     systemImage: "sun.max")
        }
    }
}

private struct InfoTile: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: systemImage)
                .font(.footnote)
                .foregroundColor(.secondary)
            Text(value).bold()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.gray.opacity(0.08)))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("\(title) \(value)"))
    }
}

private struct CareRow: View {
    @ObservedObject var task: CareTask
    var completeAction: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconName(for: task.type))
                .imageScale(.large)

            VStack(alignment: .leading, spacing: 2) {
                Text((task.type ?? "Task").capitalized).bold()
                Text("Due \(task.dueDate?.formatted(date: .abbreviated, time: .omitted) ?? "—")")
                    .foregroundColor(.secondary)
                    .font(.footnote)
            }

            Spacer()

            Button(action: completeAction) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .imageScale(.large)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(task.isCompleted ? "Completed" : "Mark complete"))
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.gray.opacity(0.08)))
    }

    private func iconName(for type: String?) -> String {
        switch type {
        case CareType.water.rawValue: return "drop.fill"
        case CareType.fertilize.rawValue: return "leaf.arrow.triangle.circlepath"
        case CareType.prune.rawValue: return "scissors"
        case CareType.repot.rawValue: return "arrow.up.arrow.down.circle"
        default: return "checklist"
        }
    }
}

private struct HealthLogList: View {
    @ObservedObject var plant: Plant

    var body: some View {
        let logs = (plant.logs?.allObjects as? [HealthLog] ?? [])
            .sorted { ($0.date ?? .distantPast) > ($1.date ?? .distantPast) }

        if logs.isEmpty {
            Text("No logs yet.")
                .foregroundColor(.secondary)
        } else {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(logs, id: \.id) { log in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(log.date?.formatted(date: .abbreviated, time: .omitted) ?? "")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        if let note = log.note, !note.isEmpty {
                            Text(note)
                        }
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.gray.opacity(0.08)))
                }
            }
        }
    }
}

private struct ActionBar: View {
    var addWater: () -> Void
    var addHealth: () -> Void
    var addPhoto: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: addWater) {
                Label("Add Task", systemImage: "plus")
            }
            .buttonStyle(.bordered)

            Button(action: addHealth) {
                Label("Log Health", systemImage: "heart.text.square")
            }
            .buttonStyle(.bordered)

            Button(action: addPhoto) {
                Label("Add Photo", systemImage: "camera")
            }
            .buttonStyle(.bordered)
        }
        .padding(.vertical)
    }
}
