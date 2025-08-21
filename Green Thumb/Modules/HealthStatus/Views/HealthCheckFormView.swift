import SwiftUI

public struct HealthCheckFormView: View {
    public var onSave: (HealthManualCheck) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var selected: Set<HealthManualSymptom> = []
    @State private var note: String = ""

    public init(onSave: @escaping (HealthManualCheck) -> Void) {
        self.onSave = onSave
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section("Observed Symptoms") {
                    ForEach(HealthManualSymptom.allCases) { s in
                        Toggle(isOn: Binding(
                            get: { selected.contains(s) },
                            set: { new in
                                if new { selected.insert(s) } else { selected.remove(s) }
                            }
                        )) {
                            Text(label(for: s))
                        }
                    }
                }

                Section("Notes") {
                    TextField("Anything else…", text: $note, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Manual Health Check")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(.init(date: .now, symptoms: selected, note: note.isEmpty ? nil : note))
                        dismiss()
                    }
                    .disabled(selected.isEmpty && note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func label(for s: HealthManualSymptom) -> String {
        switch s {
        case .wilting: return "Wilting"
        case .yellowing: return "Yellowing"
        case .brownSpots: return "Brown spots"
        case .leafDrop: return "Leaf drop"
        case .pestsSeen: return "Pests seen"
        case .stunted: return "Stunted growth"
        }
    }
}
