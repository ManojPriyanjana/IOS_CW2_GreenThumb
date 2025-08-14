import SwiftUI

struct SpeciesStepView: View {
    @ObservedObject var state: NewPlantState

    let suggestions = ["Monstera deliciosa","Epipremnum aureum (Pothos)","Ficus lyrata (Fiddle leaf fig)","Sansevieria (Snake plant)"]

    var body: some View {
        Form {
            Section(header: Text("Plant name")) {
                TextField("Common name (e.g., Monstera)", text: $state.commonName)
                    .textInputAutocapitalization(.words)
                TextField("Scientific name (optional)", text: $state.scientificName)
                    .textInputAutocapitalization(.words)
            }
            Section(header: Text("Suggestions")) {
                ForEach(suggestions, id: \.self) { s in
                    Button(s) {
                        state.commonName = s.components(separatedBy: " (").first ?? s
                        if s.contains("(") { state.scientificName = s }
                    }
                }
            }
        }
        .navigationTitle("Species")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) { Button("Back") { state.step -= 1 } }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Next") { state.step += 1 }.disabled(!state.canContinue)
            }
        }
    }
}
