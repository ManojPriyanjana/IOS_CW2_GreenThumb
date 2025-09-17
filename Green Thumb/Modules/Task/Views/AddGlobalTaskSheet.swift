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
    @State private var selectedPlantID: NSManagedObjectID? = nil // stable selection for Picker
    @State private var title = ""

    // Quick types
    private let types = ["watering","fertilizing","pruning","harvesting","health"]
    @State private var type = "watering"

    // Priority (0/1/2)
    @State private var priority: Int = 1

    // Due date
    @State private var hasDue = true
    @State private var due = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
    // Local notification
    @State private var notify = false
    private var selectedPlant: Plant? { // resolve from fetched list to avoid context faults
        guard let id = selectedPlantID else { return nil }
        return plants.first(where: { $0.objectID == id })
    }
    private var hasPlantSelection: Bool { fixedPlant != nil || selectedPlantID != nil }
    @State private var showSaveError = false
    @State private var saveErrorMessage = ""
    enum NotifyFrequency: String, CaseIterable, Identifiable { case once, daily, weekly, monthly; var id: String { rawValue } }
    @State private var frequency: NotifyFrequency = .once
    @State private var timeOnly: Date = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var onceDate: Date = Date().addingTimeInterval(3600)
    @State private var weekday: Int = Calendar.current.component(.weekday, from: Date()) // 1=Sun..7=Sat
    @State private var monthDay: Int = Calendar.current.component(.day, from: Date())

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
                        NavigationLink {
                            PlantPickerListView(selectedPlantID: $selectedPlantID)
                        } label: {
                            HStack {
                                Text("Plant")
                                Spacer()
                                Text(selectedPlant?.name ?? "No plant")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Text("Optional: link this task to a plant.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
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

                    // Replaced grid of pills with a horizontal row of round icon options
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(types, id: \.self) { t in
                                RoundIconOption(
                                    selected: type == t,
                                    label: t.capitalized,
                                    systemImage: icon(for: t)
                                ) { type = t }
                            }
                        }
                        .padding(.horizontal, 2)
                    }
                    .padding(.vertical, 4)
                    .animation(.none, value: type)

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
                Section("Notification") {
                    Toggle("Notify me", isOn: $notify)
                    Group {
                        if notify {
                        Picker("Frequency", selection: $frequency) {
                            Text("Once").tag(NotifyFrequency.once)
                            Text("Daily").tag(NotifyFrequency.daily)
                            Text("Weekly").tag(NotifyFrequency.weekly)
                            Text("Monthly").tag(NotifyFrequency.monthly)
                        }
                        if frequency == .once {
                            DatePicker("Date", selection: $onceDate, displayedComponents: [.date, .hourAndMinute])
                        } else {
                            DatePicker("Time", selection: $timeOnly, displayedComponents: .hourAndMinute)
                        }
                        if frequency == .weekly {
                            Picker("Day", selection: $weekday) {
                                Text("Sun").tag(1); Text("Mon").tag(2); Text("Tue").tag(3);
                                Text("Wed").tag(4); Text("Thu").tag(5); Text("Fri").tag(6); Text("Sat").tag(7)
                            }
                        } else if frequency == .monthly {
                            Picker("Day", selection: $monthDay) {
                                ForEach(1...31, id: \.self) { Text("\($0)").tag($0) }
                            }
                        }
                        }
                    }
                    .animation(.none, value: notify)
                    .animation(.none, value: frequency)
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
            .alert("Unable to save task", isPresented: $showSaveError) {
                Button("OK", role: .cancel) { }
            } message: { Text(saveErrorMessage) }
            .onAppear {
                // Preselect and lock if scoped
                if let fixed = fixedPlant { selectedPlantID = fixed.objectID }
                // Default once date to due date if set, else soon
                onceDate = hasDue ? due : Date().addingTimeInterval(3600)
            }
        }
    }

    // Save
    private func save() {
        do {
            let t = try TaskRepository(ctx: ctx).create(
        for: fixedPlant ?? selectedPlant,   // use fixedPlant if present
                title: title,
                type: type,
                dueDate: hasDue ? due : nil,
                priority: Int16(priority)
            )
        if notify, let id = t.id?.uuidString {
                NotificationManager.shared.requestAuth { granted in
                    guard granted else { return }
            let titleText = title.isEmpty ? "Task" : title
            let plantName = fixedPlant?.name ?? selectedPlant?.name ?? "Plant"
            let bodyText = "\(type.capitalized) for \(plantName)"
                    switch frequency {
                    case .once:
                        NotificationManager.shared.scheduleOnce(id: id, title: titleText, body: bodyText, at: onceDate)
                    case .daily:
                        let h = Calendar.current.component(.hour, from: timeOnly)
                        let m = Calendar.current.component(.minute, from: timeOnly)
                        NotificationManager.shared.scheduleDaily(id: id, title: titleText, body: bodyText, hour: h, minute: m)
                    case .weekly:
                        let h = Calendar.current.component(.hour, from: timeOnly)
                        let m = Calendar.current.component(.minute, from: timeOnly)
                        NotificationManager.shared.scheduleWeekly(id: id, title: titleText, body: bodyText, weekday: weekday, hour: h, minute: m)
                    case .monthly:
                        let h = Calendar.current.component(.hour, from: timeOnly)
                        let m = Calendar.current.component(.minute, from: timeOnly)
                        NotificationManager.shared.scheduleMonthly(id: id, title: titleText, body: bodyText, day: monthDay, hour: h, minute: m)
                    }
                }
            }

            // Auto-sync to Calendar if enabled
            if UserDefaultsSettingsStore().load().syncTasksToCalendar {
                let titleText = title.isEmpty ? "Task" : title
                let start = hasDue ? due : Date()
                let end = start.addingTimeInterval(60 * 60)
                var parts: [String] = []
                let plantName = fixedPlant?.name ?? selectedPlant?.name
                if let p = plantName, !p.isEmpty { parts.append("Plant: \(p)") }
                parts.append("Type: \(type.capitalized)")
                let notes = parts.joined(separator: "\n")
                let key = t.objectID.uriRepresentation().absoluteString
                EventKitService.shared.createOrUpdateEvent(scheduleKey: key,
                                                           title: titleText,
                                                           start: start,
                                                           end: end,
                                                           notes: notes) { _ in }
            }
            dismiss()
        } catch {
            saveErrorMessage = error.localizedDescription
            showSaveError = true
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

// New: circular icon option used for task type selection
private struct RoundIconOption: View {
    let selected: Bool
    let label: String
    let systemImage: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(selected ? Color.green.opacity(0.2) : Color.gray.opacity(0.12))
                        .frame(width: 48, height: 48)
                    Image(systemName: systemImage)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(selected ? Color.green : .primary)
                }
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(selected ? Color.green : .secondary)
                    .lineLimit(1)
                    .frame(width: 60)
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(label))
        .accessibilityAddTraits(selected ? .isSelected : [])
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

// Invisible spacer cell to keep the grid balanced (so columns align nicely)
private struct PlaceholderCell: View {
    var body: some View {
        Color.clear.frame(height: 0)
    }
}
