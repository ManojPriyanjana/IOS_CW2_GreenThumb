import SwiftUI
import CoreData

/// Add Task sheet. If `fixedPlant` is provided, the Plant picker is hidden and the task is
/// saved for that specific plant. Otherwise it's a normal "global" add with a Plant picker.
struct AddGlobalTaskSheet: View {
    @Environment(\.managedObjectContext) private var ctx
    @Environment(\.dismiss) private var dismiss

    // If not nil, the sheet is "scoped" to this plant.
    let fixedPlant: Plant?

    // Load plants only for global mode
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Plant.name, ascending: true)])
    private var plants: FetchedResults<Plant>

    // Form state
    @State private var selectedPlant: Plant? = nil            // may be nil (general task)
    @State private var title = ""

    // Quick types
    private let types = ["watering","fertilizing","pruning","harvesting","health"]
    @State private var type = "watering"

    // Priority (0/1/2)
    @State private var priority: Int = 1

    // Due date
    @State private var hasDue = true
    @State private var due = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()

    init(fixedPlant: Plant? = nil) {
        self.fixedPlant = fixedPlant
        // NOTE: we can't set @State here; we set it in .onAppear below
    }

    var body: some View {
        NavigationStack {
            Form {
                // Plant
                if fixedPlant == nil {
                    Section("Plant") {
                        Picker("Plant", selection: $selectedPlant) {
                            Text("No plant").tag(Optional<Plant>.none)
                            ForEach(plants) { p in
                                Text(p.name ?? "Plant").tag(Optional(p))
                            }
                        }
                    }
                } else {
                    // Show read-only info when scoped to a plant
                    Section("Plant") {
                        HStack {
                            Text("Plant")
                            Spacer()
                            Text(fixedPlant?.name ?? "Plant")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // Details
                Section("Details") {
                    TextField("Title (e.g., Water 500ml)", text: $title)

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 8)], spacing: 8) {
                        ForEach(types, id: \.self) { t in
                            SelectablePill(
                                selected: type == t,
                                label: t.capitalized,
                                systemImage: icon(for: t)
                            ) { type = t }
                        }
                    }
                    .padding(.vertical, 4)

                    HStack(spacing: 8) {
                        PrioritySelectPill(title: "Low",    color: .green,  selected: priority == 0) { priority = 0 }
                        PrioritySelectPill(title: "Medium", color: .orange, selected: priority == 1) { priority = 1 }
                        PrioritySelectPill(title: "High",   color: .red,    selected: priority == 2) { priority = 2 }
                    }
                    .padding(.vertical, 2)
                }

                // Due date
                Section("Due date") {
                    Toggle("Set due date", isOn: $hasDue)
                    if hasDue {
                        DatePicker("Due", selection: $due, displayedComponents: [.date, .hourAndMinute])
                    }
                }
            }
            .navigationTitle("Add Task")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                // Preselect and lock if scoped
                if let fixed = fixedPlant { selectedPlant = fixed }
            }
        }
    }

    // Save
    private func save() {
        do {
            _ = try TaskRepository(ctx: ctx).create(
                for: fixedPlant ?? selectedPlant,   // use fixedPlant if present
                title: title,
                type: type,
                dueDate: hasDue ? due : nil,
                priority: Int16(priority)
            )
            dismiss()
        } catch {
            print("Task save error:", error)
        }
    }

    //Icons
    private func icon(for type: String) -> String {
        switch type {
        case "watering":    return "drop.fill"
        case "pruning":     return "scissors"
        case "fertilizing": return "leaf.circle"
        case "harvesting":  return "basket.fill"
        case "health":      return "heart.text.square"
        default:            return "checklist"
        }
    }
}

// Small UI helpers
private struct SelectablePill: View {
    let selected: Bool
    let label: String
    let systemImage: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                Text(label)
            }
            .font(.footnote)
            .padding(.horizontal, 10).padding(.vertical, 6)
            .background(selected ? Color.green.opacity(0.2) : Color.gray.opacity(0.12))
            .foregroundStyle(selected ? Color.green : Color.primary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

private struct PrioritySelectPill: View {
    let title: String
    let color: Color
    let selected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(title)
                .font(.footnote)
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(selected ? color.opacity(0.2) : Color.gray.opacity(0.12))
                .foregroundStyle(selected ? color : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
