import Foundation
import CoreML
import Vision
import UIKit

final class DiseaseIdentifierViewModel: ObservableObject {
    @Published var selectedImage: UIImage? = nil
    @Published var resultLabel: String? = nil
    @Published var confidence: Double? = nil
    @Published var isProcessing = false
    @Published var errorMessage: String? = nil

    // MARK: - Public

    func classifySelectedImage() {
        guard let uiImage = selectedImage,
              let cgImage = uiImage.cgImage else {
            errorMessage = "Please select a valid image."
            return
        }
        isProcessing = true
        resultLabel = nil
        confidence = nil
        errorMessage = nil

        Task.detached { [weak self] in
            await self?.classify(cgImage: cgImage)
        }
    }

    // MARK: - Core ML + Vision

    private func classify(cgImage: CGImage) async {
        do {
            let model = try loadModelFromBundle()
            let vnModel = try VNCoreMLModel(for: model)
            let request = VNCoreMLRequest(model: vnModel)
            request.imageCropAndScaleOption = .centerCrop

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try handler.perform([request])

            guard let results = request.results as? [VNClassificationObservation],
                  let top = results.first else {
                await publishError("No classification results.")
                return
            }

            await MainActor.run {
                self.resultLabel = top.identifier
                self.confidence = Double(top.confidence)
                self.isProcessing = false
            }
        } catch {
            await publishError(error.localizedDescription)
        }
    }

    private func loadModelFromBundle() throws -> MLModel {
        // Looks for a compiled model named PlantDiseaseClassifier.mlmodelc
        guard let url = Bundle.main.url(forResource: "PlantDiseaseClassifier", withExtension: "mlmodelc") else {
            throw NSError(domain: "DiseaseIdentifier",
                          code: -1,
                          userInfo: [NSLocalizedDescriptionKey:
                                     "Model not found. Add PlantDiseaseClassifier.mlmodel to the app target."])
        }
        return try MLModel(contentsOf: url)
    }

    @MainActor
    private func publishError(_ message: String) {
        self.errorMessage = message
        self.isProcessing = false
    }
}
