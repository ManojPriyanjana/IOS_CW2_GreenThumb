import SwiftUI

struct AddEditPlantView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm: AddEditPlantViewModel
    let onSave: (Plant) -> Void

    init(existing: Plant? = nil, onSave: @escaping (Plant) -> Void) {
        _vm = StateObject(wrappedValue: AddEditPlantViewModel(existing: existing))
        self.onSave = onSave
    }

    var body: some View {
        Form {
            Section("Basics") {
                TextField("Name *", text: $vm.name)
                TextField("Species", text: $vm.species)
                TextField("Location", text: $vm.location)
            }

            Section("Watering") {
                Stepper(value: $vm.wateringIntervalDays, in: 1...60) {
                    HStack {
                        Text("Interval")
                        Spacer()
                        Text("\(vm.wateringIntervalDays) days")
                            .foregroundStyle(.secondary)
                    }
                }
                DatePicker("Last watered", selection: Binding(
                    get: { vm.lastWatered ?? Date() },
                    set: { vm.lastWatered = $0 }
                ), displayedComponents: .date)
                .environment(\.locale, Locale(identifier: "en_US_POSIX"))
                .onChange(of: vm.lastWatered) { _ in } // keep binding happy
                .labelsHidden()
                .accessibilityLabel("Last watered date")
                .overlay(alignment: .leading) {
                    Text("Last watered").font(.subheadline)
                        .padding(.leading, 16).padding(.top, -24)
                }
            }

            Section("Notes") {
                TextEditor(text: $vm.notes)
                    .frame(minHeight: 100)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary))
            }
        }
        .navigationTitle(vm.editingID == nil ? "Add Plant" : "Edit Plant")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {
                    onSave(vm.build())
                    dismiss()
                }
                .disabled(!vm.canSave)
            }
        }
    }
}
