import SwiftUI
import CoreData

/// Aggregated Health Issues across all plants with simple filters.
struct HealthListAllPlantsView: View {
    @Environment(\.managedObjectContext) private var ctx

    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \HealthIssue.status,    ascending: true),
            NSSortDescriptor(keyPath: \HealthIssue.createdAt, ascending: false)
        ],
        animation: .default
    ) private var issues: FetchedResults<HealthIssue>

    @State private var query = ""
    @State private var showOpenOnly = true

    var body: some View {
        List(filtered) { i in row(i) }
            .listStyle(.insetGrouped)
            .navigationTitle("Health Issues")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Toggle(isOn: $showOpenOnly) { Text("Open only") }
                }
            }
            .searchable(text: $query)
    }

    private var filtered: [HealthIssue] {
        let base = showOpenOnly ? issues.filter { ($0.status ?? "") != "Resolved" } : Array(issues)
        guard !query.isEmpty else { return base }
        return base.filter {
            ($0.category ?? "").localizedCaseInsensitiveContains(query) ||
            ($0.subtype ?? "").localizedCaseInsensitiveContains(query) ||
            ($0.notes ?? "").localizedCaseInsensitiveContains(query) ||
            ($0.status ?? "").localizedCaseInsensitiveContains(query)
        }
    }

    @ViewBuilder
    private func row(_ i: HealthIssue) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Image(systemName: icon(for: i.category))
                .foregroundStyle(($0.status ?? "") == "Resolved" ? .secondary : .red)
            VStack(alignment: .leading, spacing: 2) {
                Text(i.subtype?.isEmpty == false ? i.subtype! : (i.category ?? "Issue"))
                    .font(.headline)
                if let notes = i.notes, !notes.isEmpty {
                    Text(notes).font(.subheadline).foregroundStyle(.secondary).lineLimit(2)
                }
            }
            Spacer()
            Text(i.status ?? "Open").font(.caption)
        }
    }
}

// Reuse icon mapping from HealthListView
private func icon(for category: String?) -> String {
    switch (category ?? "").lowercased() {
    case "pest": return "ant"
    case "fungus": return "aqi.high"
    case "deficiency": return "drop.triangle"
    default: return "exclamationmark.triangle"
    }
}
