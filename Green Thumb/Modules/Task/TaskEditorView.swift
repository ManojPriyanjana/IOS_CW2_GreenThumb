import SwiftUI

struct TaskEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = TaskEditorViewModel()

    @State private var frequencyEvery: Int = 0
    @State private var frequencyUnit: RepeatUnit = .day

    var body: some View {
        NavigationView {
            Form {
                Section("Task Type") {
                    Grid(horizontalSpacing: 12, verticalSpacing: 12) {
                        GridRow { typeTile(.watering); typeTile(.fertilizing) }
                        GridRow { typeTile(.pruning);  typeTile(.repotting)  }
                        GridRow { typeTile(.healthCheck) }
                    }
                    .padding(.vertical, 4)
                }

                Section {
                    TextField("Title", text: Binding(
                        get: { vm.item.title },
                        set: { vm.item.title = $0 })
                    )
                    TextField("Notes", text: Binding(
                        get: { vm.item.notes ?? "" },
                        set: { vm.item.notes = $0.isEmpty ? nil : $0 })
                    )
                }

                Section("Frequency") {
                    Picker("Every", selection: $frequencyEvery) {
                        Text("None").tag(0)
                        ForEach(1..<31) { Text("\($0)").tag($0) }
                    }
                    Picker("Unit", selection: $frequencyUnit) {
                        Text("days").tag(RepeatUnit.day)
                        Text("weeks").tag(RepeatUnit.week)
                        Text("months").tag(RepeatUnit.month)
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: frequencyEvery) { _ in updateRecurrence() }
                    .onChange(of: frequencyUnit)  { _ in updateRecurrence() }
                }

                Section {
                    DatePicker("Start Date", selection: $vm.item.startDate.or(Date()), displayedComponents: .date)
                    DatePicker("Due Date",   selection: $vm.item.dueDate.or(Date()),   displayedComponents: [.date, .hourAndMinute])
                    Toggle("Weather-aware adjustment", isOn: $vm.item.isWeatherAware)

                    Toggle("Remind me", isOn: Binding(
                        get: { vm.item.remindAt != nil },
                        set: { on in vm.item.remindAt = on ? (vm.item.dueDate ?? Date()) : nil })
                    )
                    if vm.item.remindAt != nil {
                        DatePicker("Alert Time", selection: $vm.item.remindAt.or(vm.item.dueDate ?? Date()), displayedComponents: .hourAndMinute)
                    }
                }

                if !vm.nextOccurrences.isEmpty {
                    Section("Next 3 Occurrences") {
                        ForEach(vm.nextOccurrences, id: \.self) { d in
                            Text(d.formatted(date: .abbreviated, time: .omitted))
                        }
                    }
                }
            }
            .navigationTitle("Add Care Task")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { Task { if await vm.save() { dismiss() } } }.bold()
                }
            }
        }
        .onAppear {
            frequencyEvery = vm.item.recurrence.every
            frequencyUnit  = vm.item.recurrence.unit
        }
    }

    private func updateRecurrence() {
        vm.item.recurrence = RecurrenceRule(every: frequencyEvery, unit: frequencyUnit)
        vm.recomputeOccurrences()
    }

    @ViewBuilder
    private func typeTile(_ t: TaskType) -> some View {
        Button {
            vm.item.type = t
            if vm.item.title.isEmpty { vm.item.title = t.label }
        } label: {
            HStack { Image(systemName: t.systemImage); Text(t.label) }
                .frame(maxWidth: .infinity)
                .padding()
                .background(vm.item.type == t ? Color.green.opacity(0.15) : Color(.secondarySystemBackground))
                .overlay(RoundedRectangle(cornerRadius: 12)
                    .stroke(vm.item.type == t ? .green : Color(.separator), lineWidth: 1))
                .cornerRadius(12)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(t.label))
    }
}
