import SwiftUI

struct HarvestRowView: View {
    @ObservedObject var plant: Plant

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            PlantAvatar(plant: plant)
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(plant.commonName ?? "Plant")
                        .font(.headline)
                    Spacer()
                    Text(plant.harvestDateRangeShort)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text(plant.harvestStatusText)
                    .font(.subheadline)
                    .foregroundStyle(
                        plant.harvestStatus == .overdue ? .red :
                        plant.harvestStatus == .bestNow ? .green : .secondary
                    )

                GTProgressBar(value: plant.harvestProgressToStart)
                    .padding(.top, 2)

                Text("\(Int(plant.harvestProgressToStart * 100))% ready")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(.secondary)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
        )
    }
}
