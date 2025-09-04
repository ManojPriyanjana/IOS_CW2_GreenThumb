import SwiftUI
import CoreData

/// Shows health issues for a single Plant
struct HealthListView: View {
    @Environment(\.managedObjectContext) private var ctx

    @ObservedObject var plant: Plant

    // Fetch issues for this plant
    @FetchRequest private var issues: FetchedResults<HealthIssue>

    @State private var showingAdd = false
    @State private var query = ""

    init(plant: Plant) {
        self.plant = plant

        let req: NSFetchRequest<HealthIssue> = HealthIssue.fetchRequest()
        // IMPORTANT: compare to the Plant object (not its objectID)
        req.predicate = NSPredicate(format: "plant == %@", plant)
        req.sortDescriptors = [
            NSSortDescriptor(keyPath: \HealthIssue.status,    ascending: true),
            NSSortDescriptor(keyPath: \HealthIssue.createdAt, ascending: false)
        ]
        _issues = FetchRequest(fetchRequest: req, animation: .default)
    }

    var body: some View {
        let open   = filtered.filter { ($0.status ?? "") != "Resolved" }
        let closed = filtered.filter { ($0.status ?? "") == "Resolved" }

        List {
            if !open.isEmpty {
                Section("Open") { ForEach(open, content: row) }
            }
            if !closed.isEmpty {
                Section("Resolved") { ForEach(closed, content: row) }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Health Issues")
        .searchable(text: $query)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showingAdd = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $showingAdd) {
            AddHealthIssueSheet(plant: plant)
        }
    }

    private var filtered: [HealthIssue] {
        guard !query.isEmpty else { return Array(issues) }
        return issues.filter {
            ($0.category ?? "").localizedCaseInsensitiveContains(query) ||
            ($0.subtype ?? "").localizedCaseInsensitiveContains(query) ||
            ($0.notes ?? "").localizedCaseInsensitiveContains(query) ||
            ($0.status ?? "").localizedCaseInsensitiveContains(query)
        }
    }

    // MARK: - Row

    @ViewBuilder
    private func row(_ i: HealthIssue) -> some View {
        let isResolved = (i.status ?? "") == "Resolved"

        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon(for: i.category))
                    .foregroundStyle(isResolved ? Color.secondary : Color.red)

                Text(i.subtype?.isEmpty == false ? i.subtype! : (i.category ?? "Issue"))
                    .font(.headline)

                Spacer()

                Text(i.status ?? "Open")
                    .font(.caption)
                    .padding(.horizontal, 6).padding(.vertical, 3)
                    .background(isResolved ? Color.green.opacity(0.15) : Color.orange.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }

            if let notes = i.notes, !notes.isEmpty {
                Text(notes).font(.subheadline).foregroundStyle(.secondary).lineLimit(3)
            }

            HStack(spacing: 8) {
                if let created = i.createdAt {
                    Text("Reported: \(created.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption).foregroundStyle(.secondary)
                }
                if let resolved = i.resolvedAt {
                    Text("• Resolved: \(resolved.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            if !isResolved {
                Button {
                    do { try HealthIssueRepository(ctx: ctx).resolve(i) } catch { print(error) }
                } label: { Label("Resolve", systemImage: "checkmark.circle.fill") }
                .tint(.green)
            } else {
                Button {
                    do { try HealthIssueRepository(ctx: ctx).reopen(i) } catch { print(error) }
                } label: { Label("Reopen", systemImage: "arrow.uturn.left") }
                .tint(.orange)
            }
        }
        .swipeActions(edge: .leading) {
            Button(role: .destructive) {
                do { try HealthIssueRepository(ctx: ctx).delete(i) } catch { print(error) }
            } label: { Label("Delete", systemImage: "trash") }
        }
    }

    private func icon(for category: String?) -> String {
        switch (category ?? "").lowercased() {
        case "pests":     return "ant"
        case "disease":   return "bandage.fill"
        case "nutrient":  return "leaf"
        case "watering":  return "drop"
        case "physical":  return "wrench.adjustable"
        default:          return "exclamationmark.triangle"
        }
    }
}
