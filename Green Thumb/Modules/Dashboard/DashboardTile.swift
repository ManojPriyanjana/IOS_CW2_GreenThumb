import SwiftUI

struct DashboardTile: View {
    let item: DashboardItem

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: item.systemImage)
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(.white)
                .padding(18)
                .background(item.color.gradient)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            Text(item.title)
                .font(.headline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.primary)
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 150)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(radius: 2, y: 1)
    }
}
