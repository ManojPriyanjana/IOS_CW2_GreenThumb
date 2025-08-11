import Foundation
import CoreML
import Vision
import UIKit

final class DiseaseIdentifierViewModel: ObservableObject {
    @Published var selectedImage: UIImage? = nil
    @Published var resultLabel: String? = nil
    @Published var confidence: Double? = nil          // 0.0 ... 1.0
    @Published var isProcessing = false
    @Published var errorMessage: String? = nil

    // MARK: - Public

    func classifySelectedImage() {
        guard let uiImage = selectedImage, let cgImage = uiImage.cgImage else {
            errorMessage = "Please select a valid image."
            return
        }

        isProcessing = true
        resultLabel = nil
        confidence = nil
        errorMessage = nil

        Task(priority: .userInitiated) { [weak self] in
            await self?.classify(cgImage: cgImage)
        }
    }

    // MARK: - Core ML + Vision

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

            // Normalize to probabilities in case the model returns logits or weird values.
            let normalized = normalize(results)
            guard let top = normalized.first else {
                await publishError("No classification results.")
                return
            }

            await MainActor.run {
                self.resultLabel  = top.label
                self.confidence   = top.prob     // 0…1
                self.isProcessing = false
            }
        } catch {
            await publishError("Model error: \(error.localizedDescription)")
        }
    }

    // MARK: - Normalization

    /// Convert raw VN results to sorted (label, probability) pairs.
    /// If confidences look like logits (>1) we apply softmax. Otherwise we clamp to 0…1.
    private func normalize(_ results: [VNClassificationObservation]) -> [(label: String, prob: Double)] {
        let raw: [(String, Double)] = results.map { ($0.identifier, Double($0.confidence)) }

        let needsSoftmax = raw.contains { $0.1 > 1.0 } || raw.reduce(0) { $0 + $1.1 } > 1.0001
        if needsSoftmax {
            // Softmax on raw scores
            let maxLogit = raw.map { $0.1 }.max() ?? 0
            let exps = raw.map { exp($0.1 - maxLogit) }
            let sum  = max(exps.reduce(0, +), .leastNonzeroMagnitude)
            let probs = zip(raw.map { $0.0 }, exps.map { $0 / sum })
            return probs.sorted { $0.1 > $1.1 }
        } else {
            // Already probabilities—just clamp and sort
            let probs = raw.map { ($0.0, min(max($0.1, 0.0), 1.0)) }
            return probs.sorted { $0.1 > $1.1 }
        }
    }

    // MARK: - Model loader (filename-first with smart fallbacks)

    /// Looks for a compiled Core ML model in the app bundle.
    /// Name your file `PlantDiseaseClassifier.mlmodel` (or `.mlpackage`) with Target Membership checked.
    private func loadModel() throws -> MLModel {
        let fm = FileManager.default

        // 1) Expected compiled name (from .mlmodel or .mlpackage)
        if let url = Bundle.main.url(forResource: "PlantDiseaseClassifier", withExtension: "mlmodelc") {
            print("Using model: \(url.lastPathComponent)")
            return try MLModel(contentsOf: url)
        }

        // 2) Common alternate (your earlier test model)
        if let url = Bundle.main.url(forResource: "MobileNetV2", withExtension: "mlmodelc") {
            print("Using model (MobileNetV2): \(url.lastPathComponent)")
            return try MLModel(contentsOf: url)
        }

        // 3) Any compiled model present
        if let all = Bundle.main.urls(forResourcesWithExtension: "mlmodelc", subdirectory: nil),
           let first = all.first {
            let names = all.map { $0.lastPathComponent }.joined(separator: ", ")
            print("Expected PlantDiseaseClassifier.mlmodelc; found: [\(names)]. Using \(first.lastPathComponent)")
            return try MLModel(contentsOf: first)
        }

        // 4) Compile raw .mlmodel at runtime if present (rare—Xcode usually compiles for you)
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

        // 5) Helpful error
        var hint = "Add PlantDiseaseClassifier.mlmodel (or .mlpackage) to the project and check Target Membership."
        if let bundlePath = Bundle.main.bundlePath as String? {
            hint += " App bundle: \(bundlePath)"
            if let enumerator = fm.enumerator(atPath: bundlePath) {
                let mlc = enumerator.compactMap { ($0 as? String)?.hasSuffix(".mlmodelc") == true ? ($0 as? String) : nil }
                if !mlc.isEmpty { hint += " Found compiled models: \(mlc.joined(separator: ", "))" }
            }
        }
        throw NSError(domain: "DiseaseIdentifier", code: -404,
                      userInfo: [NSLocalizedDescriptionKey: "Model not found in bundle. \(hint)"])
    }

    // MARK: - Helpers

    @MainActor
    private func publishError(_ message: String) {
        self.errorMessage = message
        self.isProcessing = false
    }
}

