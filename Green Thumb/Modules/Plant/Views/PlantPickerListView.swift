import SwiftUI
import CoreData

/// A simple searchable list of registered plants for picking one, or skipping (clearing selection).
struct PlantPickerListView: View {
    @Environment(\.managedObjectContext) private var ctx
    @Environment(\.dismiss) private var dismiss

    @Binding var selectedPlantID: NSManagedObjectID?

    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Plant.name, ascending: true)])
    private var plants: FetchedResults<Plant>

    @State private var query = ""

    private var filtered: [Plant] {
        // Search by name or plant UUID string
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return Array(plants) }
        let lower = q.lowercased()
        let compact = lower.replacingOccurrences(of: "-", with: "")
        return plants.filter { p in
            let name = (p.name ?? "").lowercased()
            if name.contains(lower) { return true }
            if let uuid = p.id?.uuidString.lowercased() {
                let uuidCompact = uuid.replacingOccurrences(of: "-", with: "")
                return uuid.contains(lower) || uuidCompact.contains(compact)
            }
            return false
        }
    }

    // Shorten UUID for friendlier display (first 8 chars segment)
    private func shortID(_ id: UUID?) -> String {
        guard let s = id?.uuidString else { return "" }
        return String(s.prefix(8))
    }

    var body: some View {
        List {
            Section {
                Button {
                    selectedPlantID = nil
                    dismiss()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "nosign")
                            .foregroundStyle(.secondary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("No plant").foregroundStyle(.secondary)
                            Text("ID: —").font(.caption).foregroundStyle(.tertiary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            Section("Registered plants") {
                ForEach(filtered) { p in
                    Button {
                        selectedPlantID = p.objectID
                        dismiss()
                    } label: {
                        HStack(spacing: 12) {
                            // Photo thumbnail
                            if let data = p.photoData, let ui = UIImage(data: data) {
                                Image(uiImage: ui)
                                    .resizable().scaledToFill()
                                    .frame(width: 44, height: 44)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            } else {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.secondary.opacity(0.12))
                                        .frame(width: 44, height: 44)
                                    Image(systemName: "leaf")
                                        .foregroundStyle(.secondary)
                                }
                            }

                            // Name + short UUID (id)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(p.name ?? "Plant")
                                    .font(.headline)
                                Text("ID: \(shortID(p.id))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Select Plant")
        .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search name or ID")
        .autocorrectionDisabled(true)
    }
}
