import SwiftUI
import CoreData
import EventKit

/// A plant-scoped task list. Shows only pending tasks for the given plant,
/// with the same segmented filters as the global Tasks view.
struct PlantTasksView: View {
    @Environment(\.managedObjectContext) private var ctx

    @ObservedObject var plant: Plant

    @FetchRequest private var pendingForPlant: FetchedResults<CareTask>

    @State private var query = ""
    @State private var filter: TaskFilter = .all
    @State private var showingAdd = false
    // Calendar alert
    @State private var showCalMessage = false
    @State private var calMessage = ""

    init(plant: Plant) {
        self.plant = plant
        let req: NSFetchRequest<CareTask> = CareTask.fetchRequest()
        req.sortDescriptors = [
            NSSortDescriptor(keyPath: \CareTask.dueDate,   ascending: true),
            NSSortDescriptor(keyPath: \CareTask.createdAt, ascending: true)
        ]
        // Scope to this plant (and only not completed)
        req.predicate = NSPredicate(format: "status != %@ AND plant == %@", "Completed", plant)
        _pendingForPlant = FetchRequest(fetchRequest: req, animation: .default)
    }

    var body: some View {
        Group {
            if filtered.isEmpty {
                ContentUnavailableView("No tasks for \(plant.name ?? "this plant")",
                                       systemImage: "checklist",
                                       description: Text("Tap + to add a task for this plant."))
            } else {
                List {
                    if !overdue.isEmpty   { Section("⏰ Overdue")  { ForEach(overdue,  content: row) } }
                    if !today.isEmpty     { Section("📅 Today")    { ForEach(today,    content: row) } }
                    if !upcoming.isEmpty  { Section("🔮 Upcoming") { ForEach(upcoming, content: row) } }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Tasks")
        .searchable(text: $query)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Picker("", selection: $filter) {
                    ForEach(TaskFilter.allCases) { f in Text(f.rawValue).tag(f) }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 320)
            }
            ToolbarItem(placement: .primaryAction) {
                Button { showingAdd = true } label: { Image(systemName: "plus") }
                    .accessibilityLabel("Add task")
            }
        }
        // 🔧 Use the same sheet, but "fixed" to this plant so it auto-links
        .sheet(isPresented: $showingAdd) { AddGlobalTaskSheet(fixedPlant: plant) }
        .alert("Calendar", isPresented: $showCalMessage) {
            Button("OK", role: .cancel) {}
        } message: { Text(calMessage) }
    }

    // MARK: - Filtering

    private var filtered: [CareTask] {
        let base = Array(pendingForPlant).filter {
            query.isEmpty ||
            ($0.title ?? "").localizedCaseInsensitiveContains(query) ||
            ($0.type ?? "").localizedCaseInsensitiveContains(query)
        }
        switch filter {
        case .all:      return base
        case .overdue:  return base.filter { isOverdue($0.dueDate) }
        case .today:    return base.filter { isToday($0.dueDate) }
        case .upcoming: return base.filter { isUpcoming($0.dueDate) }
        }
    }

    private var overdue: [CareTask]  { filtered.filter { isOverdue($0.dueDate) } }
    private var today: [CareTask]    { filtered.filter { isToday($0.dueDate) } }
    private var upcoming: [CareTask] { filtered.filter { isUpcoming($0.dueDate) } }

    private func isOverdue(_ d: Date?) -> Bool {
        guard let d else { return false }
        return d < Calendar.current.startOfDay(for: Date())
    }
    private func isToday(_ d: Date?) -> Bool {
        guard let d else { return false }
        return Calendar.current.isDateInToday(d)
    }
    private func isUpcoming(_ d: Date?) -> Bool {
        guard let d else { return false }
        return d > Calendar.current.endOfDay(for: Date())
    }

    // Row

    @ViewBuilder
    private func row(_ t: CareTask) -> some View {
        let pr: Int16 = (t.value(forKey: "priority") as? NSNumber)?.int16Value ?? 0

        HStack(spacing: 12) {
            Circle().fill(priorityColor(pr)).frame(width: 10, height: 10)
            Image(systemName: icon(for: t.type)).imageScale(.large)

            VStack(alignment: .leading, spacing: 2) {
                Text(t.title ?? "Task").font(.headline)
                if let due = t.dueDate {
                    Text(due, style: .date).font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()
            PriorityPill(value: pr)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button {
                do { try TaskRepository(ctx: ctx).markCompleted(t) } catch { print(error) }
            } label: { Label("Complete", systemImage: "checkmark.circle.fill") }
            .tint(.green)
        }
        .swipeActions(edge: .leading) {
            Button(role: .destructive) {
                do { try TaskRepository(ctx: ctx).delete(t) } catch { print(error) }
            } label: { Label("Delete", systemImage: "trash") }

            Button {
                addTaskToCalendar(t)
            } label: { Label("Calendar", systemImage: "calendar.badge.plus") }
            .tint(.indigo)
        }
        .contextMenu {
            Button { addTaskToCalendar(t) } label: { Label("Add to Calendar", systemImage: "calendar.badge.plus") }
        }
    }

    private func icon(for type: String?) -> String {
        switch (type ?? "").lowercased() {
        case "watering":    return "drop.fill"
        case "pruning":     return "scissors"
        case "fertilizing": return "leaf.circle"
        case "harvesting":  return "basket.fill"
        case "health":      return "heart.text.square"
        default:            return "checklist"
        }
    }

    private func priorityColor(_ value: Int16) -> Color {
        switch value {
        case 2: return .red
        case 1: return .orange
        default: return .green
        }
    }
}

// MARK: - EventKit (Calendar)
extension PlantTasksView {
    private func addTaskToCalendar(_ t: CareTask) {
        let title = t.title ?? "Task"
        let start = t.dueDate ?? Date()
        let end = start.addingTimeInterval(60 * 60)
        let notes: String? = {
            var parts: [String] = []
            if let name = t.plant?.name, !name.isEmpty { parts.append("Plant: \(name)") }
            if let type = t.type, !type.isEmpty { parts.append("Type: \(type)") }
            return parts.isEmpty ? nil : parts.joined(separator: "\n")
        }()

        let key = t.objectID.uriRepresentation().absoluteString
        EventKitService.shared.createOrUpdateEvent(scheduleKey: key,
                                                   title: title,
                                                   start: start,
                                                   end: end,
                                                   notes: notes) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    calMessage = "Added to Calendar"
                case .failure:
                    calMessage = "Couldn’t add to Calendar. Check permission in Settings."
                }
                showCalMessage = true
            }
        }
    }
}

// Reuse your existing pill from AllTasksView
private struct PriorityPill: View {
    let value: Int16
    var body: some View {
        let label = (value == 2 ? "High" : value == 1 ? "Med" : "Low")
        Text(label)
            .font(.caption2)
            .padding(.horizontal, 6).padding(.vertical, 3)
            .background(Color.green.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

private enum TaskFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case overdue = "Overdue"
    case today = "Today"
    case upcoming = "Upcoming"
    var id: String { rawValue }
}

private extension Calendar {
    func endOfDay(for date: Date) -> Date {
        self.date(bySettingHour: 23, minute: 59, second: 59, of: date) ?? date
    }
}
