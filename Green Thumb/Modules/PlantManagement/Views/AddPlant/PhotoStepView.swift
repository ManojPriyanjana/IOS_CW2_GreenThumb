import SwiftUI
import PhotosUI

struct PhotoStepView: View {
    @ObservedObject var state: NewPlantState

    var body: some View {
        VStack(spacing: 16) {
            StepperHeader(titles: ["Photo","Species","Details","Preview"], current: state.step)

            Text("Add a photo of your plant")
                .font(.title3).bold()
            Text("This helps us identify species and track growth.")
                .foregroundColor(AppTheme.muted)

            ZStack {
                RoundedRectangle(cornerRadius: 12).stroke(style: StrokeStyle(lineWidth: 1, dash: [6]))
                    .foregroundColor(.gray.opacity(0.4))
                    .frame(height: 240)

                if let data = state.imageData, let uiImg = UIImage(data: data) {
                    Image(uiImage: uiImg).resizable().scaledToFill()
                        .frame(height: 240).clipped().cornerRadius(12)
                        .accessibilityLabel(Text("Selected plant photo"))
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "camera").font(.system(size: 32))
                        Text("No photo selected").foregroundColor(AppTheme.muted)
                        Text("Tap to add photo").font(.footnote).foregroundColor(AppTheme.muted)
                    }
                }
            }
            .onTapGesture { } // purely visual
            .padding(.horizontal)

            PhotosPicker(selection: $state.selectedItem, matching: .images) {
                Label("Choose from Library", systemImage: "photo")
                    .frame(maxWidth: .infinity).padding()
                    .background(AppTheme.bg).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.3)))
            }
            .onChange(of: state.selectedItem) { item in
                Task { state.imageData = try? await item?.loadTransferable(type: Data.self) }
            }
            .accessibilityLabel(Text("Choose photo from library"))

            Button {
                state.step += 1
            } label: {
                Text("Continue").bold().frame(maxWidth: .infinity).padding()
                    .background(state.canContinue ? AppTheme.brand : Color.gray.opacity(0.3))
                    .foregroundColor(.white).cornerRadius(12)
            }
            .disabled(!state.canContinue)

            VStack(spacing: 4) {
                Label("Photo Tips", systemImage: "lightbulb")
                Text("Good lighting • whole plant visible")
                    .foregroundColor(AppTheme.muted).font(.footnote)
            }
            .padding(.top, 8)
        }
        .padding()
        .navigationTitle("Add Plant")
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Skip") { state.step += 1 } } }
    }
}
