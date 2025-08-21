import SwiftUI

public struct PlantHealthRing: View {
    public var score: Double
    public var status: PlantHealthStatus

    public init(score: Double, status: PlantHealthStatus) {
        self.score = score
        self.status = status
    }

    public var body: some View {
        ZStack {
            Circle().stroke(Color.gray.opacity(0.15), lineWidth: 8)
            Circle()
                .trim(from: 0, to: max(0.05, score/100))
                .stroke(style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .foregroundStyle(colorFor(status))
                .rotationEffect(.degrees(-90))
            Text(String(Int(score))).font(.caption.monospacedDigit())
        }
        .accessibilityLabel("Health score \(Int(score)), \(status.rawValue)")
    }

    private func colorFor(_ s: PlantHealthStatus) -> Color {
        switch s {
        case .good: return .green
        case .watch: return .yellow
        case .atRisk: return .orange
        case .critical: return .red
        }
    }
}
