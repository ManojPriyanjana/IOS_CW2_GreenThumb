import SwiftUI
import Foundation

public struct HealthDetailView: View {
    public let plant: HealthPlant
    @ObservedObject var center: HealthCenter
    @State private var showManualCheck = false

    public init(plant: HealthPlant, center: HealthCenter) {
        self.plant = plant
        self.center = center
    }

    public var body: some View {
        let latest = center.history(for: plant.id, limit: 1).first
        ScrollView {
            VStack(spacing: 16) {
                if let latest {
                    PlantHealthRing(score: latest.score, status: latest.status)
                        .frame(width: 100, height: 100)
                        .padding(.top, 8)

                    Text(latest.status.rawValue).font(.title2.weight(.semibold))

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Contributing Factors").font(.headline)
                        ForEach(latest.factors) { f in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Circle().fill(Color.gray.opacity(0.2)).frame(width: 8, height: 8)
                                    Text(f.title).bold()
                                    Spacer()
                                    Text("−\(Int(f.impact))").foregroundStyle(.secondary)
                                }
                                Text(f.detail).foregroundStyle(.secondary).font(.subheadline)
                            }
                            .padding(8)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.gray.opacity(0.05)))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Suggested Actions").font(.headline)
                        actionButton(title: "Create Watering Task", systemImage: "drop.fill") { /* hook Task module */ }
                        actionButton(title: "Open Disease Detection", systemImage: "leaf.circle") { /* open module */ }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                let hist = center.history(for: plant.id, limit: 10)
                if hist.count > 1 {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("History").font(.headline)
                        ForEach(hist) { r in
                            HStack {
                                Text(r.date.formatted(date: .abbreviated, time: .shortened))
                                Spacer()
                                Text("\(Int(r.score)) • \(r.status.rawValue)")
                            }
                            .font(.subheadline)
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle(plant.name)
        .toolbar { Button("Manual Check") { showManualCheck = true } }
        .sheet(isPresented: $showManualCheck) {
            HealthCheckFormView { manual in
                center.addManualCheck(for: plant, manual: manual)
            }
        }
    }

    private func actionButton(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: systemImage)
                Text(title)
                Spacer()
                Image(systemName: "chevron.right")
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 14).fill(Color.green.opacity(0.10)))
        }
        .buttonStyle(.plain)
    }
}
