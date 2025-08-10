import SwiftUI

struct DiseaseIdentifierView: View {
    @StateObject private var vm = DiseaseIdentifierViewModel()
    @State private var showPicker = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header
                VStack(spacing: 4) {
                    Text("Plant Disease Identifier")
                        .font(.title2).bold()
                    Text("Select a leaf photo to analyze on-device.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top)

                // Image preview
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.secondarySystemBackground))
                        .frame(height: 240)

                    if let image = vm.selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 240)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .accessibilityLabel("Selected plant image")
                    } else {
                        VStack(spacing: 8) {
                            Image(systemName: "photo.on.rectangle")
                                .font(.system(size: 40))
                            Text("No image selected")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // Buttons
                HStack {
                    Button {
                        showPicker = true
                    } label: {
                        Label("Select Photo", systemImage: "photo")
                    }
                    .buttonStyle(.bordered)

                    Button {
                        vm.classifySelectedImage()
                    } label: {
                        Label("Identify Disease", systemImage: "bolt.heart")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(vm.selectedImage == nil || vm.isProcessing)
                }

                // Status / result
                if vm.isProcessing {
                    ProgressView("Analyzing…")
                }

                if let label = vm.resultLabel, let conf = vm.confidence {
                    resultCard(title: label, confidence: conf)
                }

                if let err = vm.errorMessage {
                    Text(err)
                        .foregroundColor(.red)
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)
                }

                Spacer(minLength: 24)
            }
            .padding(.horizontal)
        }
        .sheet(isPresented: $showPicker) {
            ImagePicker(image: $vm.selectedImage)
        }
        .navigationTitle("Disease ID")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func resultCard(title: String, confidence: Double) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Result").font(.headline)
            Text(title).font(.title3).bold()
            Text(String(format: "Confidence: %.1f%%", confidence * 100))
                .foregroundStyle(.secondary)

            // Simple advice placeholder — you can map labels to advice later.
            Divider()
            Text("Tip")
                .font(.subheadline).bold()
            Text("Inspect multiple leaves. Ensure good lighting and a clear photo of the diseased area.")
                .font(.subheadline)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemBackground)))
    }
}
