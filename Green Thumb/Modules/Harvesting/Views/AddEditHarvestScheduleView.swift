import SwiftUI
import CoreData

struct AddEditHarvestScheduleView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var ctx

    let plant: Plant?
    let schedule: HarvestSchedule?

    // Local, simple state (prefilled in init for edit case)
    @State private var expectedStart: Date
    @State private var useEndDate: Bool
    @State private var expectedEnd: Date
    @State private var scheduleType: String
    @State private var notes: String
    @State private var notify = false
    enum NotifyFrequency: String, CaseIterable, Identifiable { case once, daily, weekly, monthly; var id: String { rawValue } }
    @State private var frequency: NotifyFrequency = .once
    @State private var timeOnly: Date = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var onceDate: Date = Date().addingTimeInterval(3600)
    @State private var weekday: Int = Calendar.current.component(.weekday, from: Date())
    @State private var monthDay: Int = Calendar.current.component(.day, from: Date())

    // MARK: - Inits
    init(plant: Plant) {
        self.plant = plant
        self.schedule = nil
        _expectedStart = State(initialValue: Date())
        _useEndDate    = State(initialValue: false)
        _expectedEnd   = State(initialValue: Date().addingTimeInterval(24*3600))
        _scheduleType  = State(initialValue: "One-off")
        _notes         = State(initialValue: "")
    }

    init(schedule: HarvestSchedule) {
        self.plant = nil
        self.schedule = schedule
        let start = schedule.expectedStart ?? Date()
        _expectedStart = State(initialValue: start)
        if let end = schedule.expectedEnd {
            _useEndDate  = State(initialValue: true)
            _expectedEnd = State(initialValue: end)
        } else {
            _useEndDate  = State(initialValue: false)
            _expectedEnd = State(initialValue: start.addingTimeInterval(24*3600))
        }
        _scheduleType  = State(initialValue: schedule.scheduleType ?? "One-off")
        _notes         = State(initialValue: schedule.notes ?? "")
    }

    // MARK: - UI
    var body: some View {
        Form {
            Section("Target window") {
                DatePicker("Expected start",
                           selection: $expectedStart,
                           displayedComponents: .date)

                Toggle("Use end date", isOn: $useEndDate)
                    .onChange(of: useEndDate) { _, newValue in
                        if newValue, expectedEnd < expectedStart {
                            expectedEnd = expectedStart.addingTimeInterval(24*3600)
                        }
                    }

                if useEndDate {
                    DatePicker("Expected end",
                               selection: $expectedEnd,
                               in: expectedStart...,
                               displayedComponents: .date)
                }
            }

            Section("Type & notes") {
                Picker("Schedule type", selection: $scheduleType) {
                    Text("One-off").tag("One-off")
                    Text("Weekly").tag("Weekly")
                    Text("Biweekly").tag("Biweekly")
                    Text("Custom").tag("Custom")
                }
                TextField("Notes (optional)", text: $notes, axis: .vertical)
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
                }
            }
        }
        .navigationTitle(schedule == nil ? "Add Harvest" : "Edit Harvest")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { save() }
                    .tint(.green)
            }
        }
    }

    // MARK: - Save
    private func save() {
        do {
            if let schedule {
                try HarvestRepository.updateSchedule(
                    schedule,
                    expectedStart: expectedStart,
                    expectedEnd: useEndDate ? expectedEnd : nil,
                    scheduleType: scheduleType,
                    reminderID: nil,
                    notes: notes.isEmpty ? nil : notes,
                    in: ctx
                )
                if notify, let id = schedule.id?.uuidString {
                    NotificationManager.shared.requestAuth { granted in
                        guard granted else { return }
                        let title = "Harvest: \(schedule.plant?.name ?? "Plant")"
                        scheduleHarvestNotification(id: id, title: title)
                    }
                }
            } else if let plant {
                let created = try HarvestRepository.addSchedule(
                    for: plant,
                    expectedStart: expectedStart,
                    expectedEnd: useEndDate ? expectedEnd : nil,
                    scheduleType: scheduleType,
                    reminderID: nil,
                    notes: notes.isEmpty ? nil : notes,
                    in: ctx
                )
                if notify, let id = created.id?.uuidString {
                    NotificationManager.shared.requestAuth { granted in
                        guard granted else { return }
                        let title = "Harvest: \(plant.name ?? "Plant")"
                        scheduleHarvestNotification(id: id, title: title)
                    }
                }
            }
            dismiss()
        } catch {
            print("Harvest schedule save error:", error)
        }
    }

    private func scheduleHarvestNotification(id: String, title: String) {
        switch frequency {
        case .once:
            NotificationManager.shared.scheduleOnce(id: id, title: title, body: notes.isEmpty ? "Upcoming harvest" : notes, at: onceDate)
        case .daily:
            let h = Calendar.current.component(.hour, from: timeOnly)
            let m = Calendar.current.component(.minute, from: timeOnly)
            NotificationManager.shared.scheduleDaily(id: id, title: title, body: notes.isEmpty ? "Upcoming harvest" : notes, hour: h, minute: m)
        case .weekly:
            let h = Calendar.current.component(.hour, from: timeOnly)
            let m = Calendar.current.component(.minute, from: timeOnly)
            NotificationManager.shared.scheduleWeekly(id: id, title: title, body: notes.isEmpty ? "Upcoming harvest" : notes, weekday: weekday, hour: h, minute: m)
        case .monthly:
            let h = Calendar.current.component(.hour, from: timeOnly)
            let m = Calendar.current.component(.minute, from: timeOnly)
            NotificationManager.shared.scheduleMonthly(id: id, title: title, body: notes.isEmpty ? "Upcoming harvest" : notes, day: monthDay, hour: h, minute: m)
        }
    }
}
