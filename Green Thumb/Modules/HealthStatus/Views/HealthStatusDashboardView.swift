import SwiftUI

public struct HealthStatusDashboardView: View {
    @StateObject private var center: HealthCenter

    public init(center: HealthCenter? = nil) {
        if let center { _center = StateObject(wrappedValue: center) }
        else {
            _center = StateObject(wrappedValue: HealthCenter(
                plants: DemoPlantSource(),
                tasks: DemoTaskHistorySource(),
                diseases: DemoDiseaseResultSource(),
                weather: DemoWeatherProvider(),
                store: InMemoryHealthRecordStore()
            ))
        }
    }

    public var body: some View {
        NavigationStack {
            Group {
                if center.isLoading {
                    ProgressView("Calculating health…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let err = center.error, !err.isEmpty {
                    Text(err).foregroundStyle(.red)
                } else {
                    List(center.items) { item in
                        NavigationLink {
                            HealthDetailView(plant: item.plant, center: center)
                        } label: {
                            HealthRow(item: item)
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Plant Health")
            .toolbar { Button { Task { await center.refresh() } } label: { Image(systemName: "arrow.clockwise") } }
            .task { await center.refresh() }
        }
    }
}

private struct HealthRow: View {
    let item: HealthCenter.HealthItem
    var body: some View {
        HStack(spacing: 16) {
            PlantHealthRing(score: item.record.score, status: item.record.status)
                .frame(width: 46, height: 46)
            VStack(alignment: .leading, spacing: 4) {
                Text(item.plant.name).font(.headline)
                Text(item.record.status.rawValue).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(Int(item.record.score))")
                .font(.title3.monospacedDigit())
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(capsuleBg(for: item.record.status)).clipShape(Capsule())
        }
    }
    private func capsuleBg(for status: PlantHealthStatus) -> some ShapeStyle {
        switch status {
        case .good: return Color.green.opacity(0.15)
        case .watch: return Color.yellow.opacity(0.15)
        case .atRisk: return Color.orange.opacity(0.15)
        case .critical: return Color.red.opacity(0.15)
        }
    }
}
