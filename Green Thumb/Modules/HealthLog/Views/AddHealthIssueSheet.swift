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
            }
            .navigationTitle("Add Health Issue")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                }
            }
        }
    }

    private func save() {
        do {
            _ = try HealthIssueRepository(ctx: ctx).create(
                for: plant,
                category: category,
                subtype: subtype,
                notes: notes
            )
            dismiss()
        } catch {
            print("Health save error:", error)
        }
    }
}
