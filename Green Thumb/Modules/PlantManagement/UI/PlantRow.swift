import SwiftUI

struct PlantRow: View {
    let plant: Plant

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .strokeBorder(plant.isWateringDue ? .red : .green, lineWidth: 2)
                .frame(width: 36, height: 36)
                .overlay(Image(systemName: plant.isWateringDue ? "drop.triangle" : "leaf").font(.system(size: 16, weight: .semibold)))

            VStack(alignment: .leading, spacing: 2) {
                Text(plant.name).font(.headline)
                Text([plant.species, plant.location].filter { !$0.isEmpty }.joined(separator: " • "))
                    .font(.subheadline).foregroundStyle(.secondary)
            }

            Spacer()

            if let next = plant.nextWaterDate {
                Text(next, style: .date)
                    .font(.footnote)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
                    .accessibilityLabel("Next watering date")
            }
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
    }
}
