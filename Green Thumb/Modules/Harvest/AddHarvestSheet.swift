import SwiftUI
import CoreData

struct AddHarvestSheet: View {
    @Environment(\.managedObjectContext) private var ctx

    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Plant.dateAdded, ascending: false)])
    private var plants: FetchedResults<Plant>

    @State private var selectedPlant: Plant?
    @State private var plantedOn: Date = Date()
    @State private var minDays: Int = 60
    @State private var maxDays: Int = 75
    @State private var notes: String = "" // keep if you want to add to Plant later

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Plant") {
                    Picker("Select Plant", selection: $selectedPlant) {
                        ForEach(plants, id: \.self) { p in
                            Text(p.commonName ?? "Plant").tag(Optional(p))
                        }
                    }
                }
                Section("Dates") {
                    DatePicker("Planted on", selection: $plantedOn, displayedComponents: .date)
                    Stepper("Days to maturity (min): \(minDays)", value: $minDays, in: 1...400)
                    Stepper("Days to maturity (max): \(maxDays)", value: $maxDays, in: minDays...500)
                }
            }
            .navigationTitle("Enable Harvest")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard let plant = selectedPlant else { return }
                        plant.dateAdded = plantedOn
                        plant.maturityMinDays = Int16(minDays)
                        plant.maturityMaxDays = Int16(maxDays)
                        try? ctx.save()
                        dismiss()
                    }.disabled(selectedPlant == nil)
                }
            }
        }
    }
}
