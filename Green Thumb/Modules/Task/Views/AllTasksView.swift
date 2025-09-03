import SwiftUI
import CoreData

private enum TaskFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case overdue = "Overdue"
    case today = "Today"
    case upcoming = "Upcoming"
    var id: String { rawValue }
}

struct AllTasksView: View {
    @Environment(\.managedObjectContext) private var ctx

    @FetchRequest private var pending: FetchedResults<CareTask>

    @State private var query = ""
    @State private var filter: TaskFilter = .all
    @State private var showingAdd = false

    init() {
        let req: NSFetchRequest<CareTask> = CareTask.fetchRequest()
        req.sortDescriptors = [
            NSSortDescriptor(keyPath: \CareTask.dueDate,   ascending: true),
            NSSortDescriptor(keyPath: \CareTask.createdAt, ascending: true)
        ]
        req.predicate = NSPredicate(format: "status != %@", "Completed")
        _pending = FetchRequest(fetchRequest: req, animation: .default)
    }

    var body: some View {
        Group {
            if filtered.isEmpty {
                ContentUnavailableView("No tasks yet",
                                       systemImage: "checklist",
                                       description: Text("Tap + to add your first task."))
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
        .sheet(isPresented: $showingAdd) { AddGlobalTaskSheet() }
    }

    // MARK: - Filtering

    private var filtered: [CareTask] {
        let base = Array(pending).filter {
            query.isEmpty ||
            ($0.title ?? "").localizedCaseInsensitiveContains(query) ||
            ($0.type ?? "").localizedCaseInsensitiveContains(query) ||
            (($0.plant?.name ?? "").localizedCaseInsensitiveContains(query))
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

    // MARK: - Row

    @ViewBuilder
    private func row(_ t: CareTask) -> some View {
        // Robust priority (NSNumber bridging)
        let pr: Int16 = (t.value(forKey: "priority") as? NSNumber)?.int16Value ?? 0

        NavigationLink {
            if let p = t.plant { PlantDetailView(objectID: p.objectID) }
            else { Text("General task") }
        } label: {
            HStack(spacing: 12) {
                // Priority color dot
                Circle()
                    .fill(priorityColor(pr))
                    .frame(width: 10, height: 10)

                Image(systemName: icon(for: t.type))
                    .imageScale(.large)

                VStack(alignment: .leading, spacing: 2) {
                    Text(t.title ?? "Task").font(.headline)

                    HStack(spacing: 8) {
                        if let due = t.dueDate {
                            Text(due, style: .date).font(.caption).foregroundStyle(.secondary)
                        }
                        Text("• \((t.plant?.name?.isEmpty == false) ? (t.plant?.name ?? "") : "General")")
                            .font(.caption).foregroundStyle(.secondary)

                        PriorityPill(value: pr) 
                    }
                }
            }
        }
        // Swipe to COMPLETE (right)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button {
                do { try TaskRepository(ctx: ctx).markCompleted(t) } catch { print(error) }
            } label: { Label("Complete", systemImage: "checkmark.circle.fill") }
            .tint(.green)
        }
        // Swipe to DELETE (left)
        .swipeActions(edge: .leading) {
            Button(role: .destructive) {
                do { try TaskRepository(ctx: ctx).delete(t) } catch { print(error) }
            } label: { Label("Delete", systemImage: "trash") }
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

// Small badge showing Low/Med/High
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

private extension Calendar {
    func endOfDay(for date: Date) -> Date {
        self.date(bySettingHour: 23, minute: 59, second: 59, of: date) ?? date
    }
}
