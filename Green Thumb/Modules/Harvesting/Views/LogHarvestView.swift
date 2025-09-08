import SwiftUI
import PhotosUI
import CoreData

struct LogHarvestView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var ctx

    let schedule: HarvestSchedule

    @State private var actualDate: Date = Date()
    @State private var quantity: Double = 0
    @State private var unit: String = "kg"
    @State private var quality: String = ""
    @State private var notes: String = ""
    @State private var photoData: Data?
    @State private var photoItem: PhotosPickerItem?

    var body: some View {
        Form {
            DatePicker("Actual date", selection: $actualDate, displayedComponents: .date)

            Stepper(value: $quantity, in: 0...1_000, step: 0.1) {
                HStack {
                    Text("Quantity")
                    Spacer()
                    Text(quantity.clean) // from HarvestingUIShared.swift
                }
            }

            TextField("Unit (kg, g, bunches…)", text: $unit)
            TextField("Quality/Grade (optional)", text: $quality)
            TextField("Notes (optional)", text: $notes, axis: .vertical)

            PhotosPicker("Add photo", selection: $photoItem, matching: .images)
                .onChange(of: photoItem) { _, item in
                    guard let item else { return }
                    Task {
                        if let data = try? await item.loadTransferable(type: Data.self) {
                            await MainActor.run { photoData = data }
                        }
                    }
                }

            if let data = photoData, let img = UIImage(data: data) {
                Image(uiImage: img)
                    .resizable().scaledToFit()
                    .frame(maxHeight: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .navigationTitle("Log Harvest")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { save() }.tint(.green)
            }
        }
    }

    private func save() {
        do {
            try HarvestRepository.addLog(
                to: schedule,
                actualDate: actualDate,
                quantity: quantity,
                unit: unit,
                quality: quality.isEmpty ? nil : quality,
                notes: notes.isEmpty ? nil : notes,
                photoData: photoData,
                in: ctx
            )
            dismiss()
        } catch {
            print("Log save error:", error)
        }
    }
}
