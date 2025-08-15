
import Foundation
import CoreML
import Vision
import UIKit

final class DiseaseIdentifierViewModel: ObservableObject {

  
    struct Prediction: Identifiable {
        let id = UUID()
        let label: String
        let prob: Double   // 0...1
    }

    //  State
    @Published var selectedImage: UIImage? = nil
    @Published var resultLabel: String? = nil
    @Published var confidence: Double? = nil        // 0...1
    @Published var predictions: [Prediction] = []   // top-3
    @Published var isProcessing = false
    @Published var errorMessage: String? = nil

    /// Below this, we call the result "Unsure".
    private let minConfidence: Double = 0.55

    // Public

    func classifySelectedImage() {
        guard let uiImage = selectedImage, let cgImage = uiImage.cgImage else {
            errorMessage = "Please select a valid image."
            return
        }

        isProcessing = true
        resultLabel = nil
        confidence = nil
        errorMessage = nil
        predictions = []

        Task(priority: .userInitiated) { [weak self] in
            await self?.classify(cgImage: cgImage)
        }
    }

    // Core ML + Vision

    private func classify(cgImage: CGImage) async {
        do {
            let model = try loadModel()
            let vnModel = try VNCoreMLModel(for: model)

            let request = VNCoreMLRequest(model: vnModel)
            request.imageCropAndScaleOption = .centerCrop

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try handler.perform([request])

            guard let results = request.results as? [VNClassificationObservation],
                  !results.isEmpty else {
                await publishError("No classification results.")
                return
            }

            // Normalize and take top-3
            let norm = normalize(results)
            let top3 = Array(norm.prefix(3)).map { Prediction(label: $0.label, prob: $0.prob) }

            await MainActor.run {
                self.predictions = top3
                if let best = top3.first, best.prob >= self.minConfidence {
                    self.resultLabel  = best.label
                    self.confidence   = best.prob
                } else {
                    self.resultLabel  = "Unsure – try another photo"
                    self.confidence   = top3.first?.prob
                }
                self.isProcessing = false
            }
        } catch {
            await publishError("Model error: \(error.localizedDescription)")
        }
    }

    // Normalization

    /// Convert raw VN results to sorted (label, probability) pairs.
    /// If any "confidence" looks like a logit (>1) we softmax; else we clamp 0…1.
    private func normalize(_ results: [VNClassificationObservation]) -> [(label: String, prob: Double)] {
        let raw = results.map { ($0.identifier, Double($0.confidence)) }

        let looksLikeLogits = raw.contains { $0.1 > 1.0 } || raw.reduce(0) { $0 + $1.1 } > 1.0001
        if looksLikeLogits {
            let maxLogit = raw.map(\.1).max() ?? 0
            let exps = raw.map { exp($0.1 - maxLogit) }
            let sum = max(exps.reduce(0, +), .leastNonzeroMagnitude)
            let probs = zip(raw.map(\.0), exps.map { $0 / sum })
            return probs.sorted { $0.1 > $1.1 }
        } else {
            let probs = raw.map { ($0.0, min(max($0.1, 0.0), 1.0)) }
            return probs.sorted { $0.1 > $1.1 }
        }
    }

    // Model loader (filename-first with smart fallbacks)

    /// Works with `.mlmodelc` compiled from `.mlmodel` or `.mlpackage`
    private func loadModel() throws -> MLModel {
        // 1) Expected compiled name (from your PlantDiseaseClassifier.mlpackage)
        if let url = Bundle.main.url(forResource: "PlantDiseaseClassifier", withExtension: "mlmodelc") {
            print("Using model: \(url.lastPathComponent)")
            return try MLModel(contentsOf: url)
        }

        // 2) Fallback: old test model
        if let url = Bundle.main.url(forResource: "MobileNetV2", withExtension: "mlmodelc") {
            print("Using model (MobileNetV2): \(url.lastPathComponent)")
            return try MLModel(contentsOf: url)
        }

        // 3) Any compiled model in bundle
        if let all = Bundle.main.urls(forResourcesWithExtension: "mlmodelc", subdirectory: nil),
           let first = all.first {
            let names = all.map { $0.lastPathComponent }.joined(separator: ", ")
            print("Expected PlantDiseaseClassifier.mlmodelc; found: [\(names)]. Using \(first.lastPathComponent)")
            return try MLModel(contentsOf: first)
        }

        // 4) Compile raw .mlmodel at runtime if present
        if let raw = Bundle.main.url(forResource: "PlantDiseaseClassifier", withExtension: "mlmodel") {
            let compiled = try MLModel.compileModel(at: raw)
            print("Compiled at runtime: \(compiled.lastPathComponent)")
            return try MLModel(contentsOf: compiled)
        }
        if let rawAlt = Bundle.main.url(forResource: "MobileNetV2", withExtension: "mlmodel") {
            let compiled = try MLModel.compileModel(at: rawAlt)
            print("Compiled at runtime (MobileNetV2): \(compiled.lastPathComponent)")
            return try MLModel(contentsOf: compiled)
        }

        throw NSError(
            domain: "DiseaseIdentifier",
            code: -404,
            userInfo: [NSLocalizedDescriptionKey:
                        "Model not found. Add PlantDiseaseClassifier.mlpackage (or .mlmodel) to the project and check Target Membership."]
        )
    }

    // Helpers

    @MainActor
    private func publishError(_ message: String) {
        self.errorMessage = message
        self.isProcessing = false
    }
}

