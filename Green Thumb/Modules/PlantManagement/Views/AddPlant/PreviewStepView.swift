import SwiftUI
import CoreData

struct PreviewStepView: View {
    @Environment(\.managedObjectContext) private var ctx
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var state: NewPlantState

    var body: some View {
        VStack(spacing: 12) {
            StepperHeader(titles: ["Photo","Species","Details","Preview"], current: state.step)

            if let data = state.imageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage).resizable().scaledToFill()
                    .frame(height: 180).cornerRadius(12).padding(.horizontal)
            }

            List {
                LabeledContent("Name", value: state.commonName)
                if !state.scientificName.isEmpty { LabeledContent("Species", value: state.scientificName) }
                if !state.location.isEmpty { LabeledContent("Location", value: state.location) }
                LabeledContent("Light", value: state.lightLevel.rawValue.capitalized)
                LabeledContent("Pot size", value: "\(Int(state.potSizeCM)) cm")
                LabeledContent("Watering", value: "Every \(state.wateringFreqDays) day(s)")
                LabeledContent("Fertilize", value: "Every \(state.fertilizeFreqDays) day(s)")
            }
            .listStyle(.insetGrouped)

            Button {
                savePlant()
                dismiss()
            } label: {
                Text("Save Plant").bold().frame(maxWidth: .infinity).padding()
                    .background(AppTheme.brand).foregroundColor(.white).cornerRadius(12)
            }
            .padding()

        }
        .navigationTitle("Preview")
        .toolbar { ToolbarItem(placement: .topBarLeading) { Button("Back") { state.step -= 1 } } }
    }

    private func savePlant() {
        let plant = Plant(context: ctx)
        plant.id = UUID()
        plant.commonName = state.commonName
        plant.scientificName = state.scientificName
        plant.location = state.location
        plant.potSizeCM = state.potSizeCM
        plant.lightLevel = state.lightLevel.rawValue
        plant.healthStatus = HealthStatus.healthy.rawValue
        plant.dateAdded = Date()
        plant.photo = state.imageData
        plant.wateringFreqDays = Int16(state.wateringFreqDays)
        plant.fertilizeFreqDays = Int16(state.fertilizeFreqDays)

        // Seed initial tasks
        let water = CareTask(context: ctx)
        water.id = UUID()
        water.type = CareType.water.rawValue
        water.dueDate = Calendar.current.date(byAdding: .day, value: state.wateringFreqDays, to: Date())
        water.isCompleted = false
        water.plant = plant

        let fert = CareTask(context: ctx)
        fert.id = UUID()
        fert.type = CareType.fertilize.rawValue
        fert.dueDate = Calendar.current.date(byAdding: .day, value: state.fertilizeFreqDays, to: Date())
        fert.isCompleted = false
        fert.plant = plant

        try? ctx.save()

        // Schedule local notifications
        ReminderScheduler.shared.schedule(task: water, plantName: plant.commonName ?? "Plant")
        ReminderScheduler.shared.schedule(task: fert, plantName: plant.commonName ?? "Plant")

        state.reset()
    }
}
