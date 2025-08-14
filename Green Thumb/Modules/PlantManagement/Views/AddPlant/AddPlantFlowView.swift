import SwiftUI

struct AddPlantFlowView: View {
    @StateObject private var state = NewPlantState()

    var body: some View {
        NavigationStack {
            Group {
                switch state.step {
                case 0: PhotoStepView(state: state)
                case 1: SpeciesStepView(state: state)
                case 2: DetailsStepView(state: state)
                case 3: PreviewStepView(state: state)
                default: PhotoStepView(state: state)
                }
            }
        }
        .onAppear { ReminderScheduler.shared.requestPermission() }
    }
}

#Preview {
    AddPlantFlowView()
}
