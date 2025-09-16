import SwiftUI
import CoreData

/// Sheet to add a new HealthIssue for a single Plant
struct AddHealthIssueSheet: View {
    @Environment(\.managedObjectContext) private var ctx
    @Environment(\.dismiss) private var dismiss

    let plant: Plant

    // Simple taxonomy – tweak to your coursework doc if needed
    private let categories = ["Pests", "Disease", "Nutrient", "Watering", "Physical"]
    @State private var category = "Pests"
    @State private var subtype = ""      // e.g. "Aphids", "Powdery mildew"
    @State private var notes = ""
    @State private var notify = false
    enum NotifyFrequency: String, CaseIterable, Identifiable { case once, daily, weekly, monthly; var id: String { rawValue } }
    @State private var frequency: NotifyFrequency = .once
    @State private var timeOnly: Date = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var onceDate: Date = Date().addingTimeInterval(3600)
    @State private var weekday: Int = Calendar.current.component(.weekday, from: Date())
    @State private var monthDay: Int = Calendar.current.component(.day, from: Date())
    @State private var addToReminders = false
    
    // EventKit state
    @State private var showEKMessage = false
    @State private var ekMessage = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Category") {
                    Picker("Type", selection: $category) {
                        ForEach(categories, id: \.self, content: Text.init)
                    }
                    TextField("Subtype (e.g., Aphids)", text: $subtype)
                }

                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 120)
                        .overlay {
                            if notes.isEmpty {
                                Text("Describe symptoms, treatments, products used…")
                                    .foregroundStyle(.secondary)
                                    .padding(.top, 6)
                                    .padding(.leading, 4)
                                    .allowsHitTesting(false)
                            }
                        }
                }
                Section("Notification") {
                    Toggle("Notify me", isOn: $notify)
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
                        
                        Toggle("Add to Reminders app", isOn: $addToReminders)
                    }
                }
            }
            .navigationTitle("Add Health Issue")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                }
            }
            .alert("EventKit Status", isPresented: $showEKMessage) {
                Button("OK") { }
            } message: {
                Text(ekMessage)
            }
        }
    }

    private func save() {
        do {
            let issue = try HealthIssueRepository(ctx: ctx).create(
                for: plant,
                category: category,
                subtype: subtype,
                notes: notes
            )
            if notify, let id = issue.id?.uuidString {
                NotificationManager.shared.requestAuth { granted in
                    guard granted else { return }
                    let title = "Health: \(category)"
                    let body = (subtype.isEmpty ? "New issue" : subtype) + " for \(plant.name ?? "Plant")"
                    switch frequency {
                    case .once:
                        NotificationManager.shared.scheduleOnce(id: id, title: title, body: body, at: onceDate)
                    case .daily:
                        let h = Calendar.current.component(.hour, from: timeOnly)
                        let m = Calendar.current.component(.minute, from: timeOnly)
                        NotificationManager.shared.scheduleDaily(id: id, title: title, body: body, hour: h, minute: m)
                    case .weekly:
                        let h = Calendar.current.component(.hour, from: timeOnly)
                        let m = Calendar.current.component(.minute, from: timeOnly)
                        NotificationManager.shared.scheduleWeekly(id: id, title: title, body: body, weekday: weekday, hour: h, minute: m)
                    case .monthly:
                        let h = Calendar.current.component(.hour, from: timeOnly)
                        let m = Calendar.current.component(.minute, from: timeOnly)
                        NotificationManager.shared.scheduleMonthly(id: id, title: title, body: body, day: monthDay, hour: h, minute: m)
                    }
                }
            }
            
            // Add to EventKit Reminders if requested
            if addToReminders {
                addHealthIssueToReminders(issue)
            }

            // Auto-sync to Calendar if enabled
            if UserDefaultsSettingsStore().load().syncHealthToCalendar {
                let titleText = (subtype.isEmpty ? category : subtype)
                let start = issue.createdAt ?? Date()
                let end = start.addingTimeInterval(60 * 30)
                var lines: [String] = ["Plant: \(plant.name ?? "Plant")",
                                       "Status: \(issue.status ?? "Open")"]
                if !notes.isEmpty { lines.append(notes) }
                let notesText = lines.joined(separator: "\n")
                let key = issue.objectID.uriRepresentation().absoluteString
                EventKitService.shared.createOrUpdateEvent(scheduleKey: key,
                                                           title: titleText,
                                                           start: start,
                                                           end: end,
                                                           notes: notesText) { _ in }
            }
            
            dismiss()
        } catch {
            print("Health save error:", error)
        }
    }
    
    private func addHealthIssueToReminders(_ issue: HealthIssue) {
        let title = "Health Issue: \(category)"
        let subtitle = subtype.isEmpty ? "" : " - \(subtype)"
        let plantName = plant.name ?? "Plant"
        let reminderTitle = title + subtitle + " (\(plantName))"
        
        let notes = [
            "Plant: \(plantName)",
            "Category: \(category)",
            subtype.isEmpty ? nil : "Subtype: \(subtype)",
            notes.isEmpty ? nil : "Notes: \(notes)"
        ].compactMap { $0 }.joined(separator: "\n")
        
        let dueDate = frequency == .once ? onceDate : nil
        let key = issue.objectID.uriRepresentation().absoluteString
        
        EventKitService.shared.createOrUpdateReminder(taskKey: key, title: reminderTitle, due: dueDate, notes: notes) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    ekMessage = "Added to Reminders"
                case .failure:
                    ekMessage = "Couldn't add to Reminders. Check permission in Settings."
                }
                showEKMessage = true
            }
        }
    }
}
