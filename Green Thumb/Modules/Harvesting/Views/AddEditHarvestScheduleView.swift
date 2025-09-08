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
            } else if let plant {
                try HarvestRepository.addSchedule(
                    for: plant,
                    expectedStart: expectedStart,
                    expectedEnd: useEndDate ? expectedEnd : nil,
                    scheduleType: scheduleType,
                    reminderID: nil,
                    notes: notes.isEmpty ? nil : notes,
                    in: ctx
                )
            }
            dismiss()
        } catch {
            print("Harvest schedule save error:", error)
        }
    }
}
