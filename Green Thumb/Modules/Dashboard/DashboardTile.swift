import SwiftUI

struct DashboardTile: View {
    let item: DashboardItem

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: item.systemImage)
                .font(.title.bold())
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
        .background(
            LinearGradient(colors: [Color.white.opacity(0.85), Color.white.opacity(0.65)], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 22, style: .continuous)
        )
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(Color.black.opacity(0.06), lineWidth: 1))
        .shadow(color: Color.black.opacity(0.06), radius: 10, y: 4)
    }
}

#Preview {
    DashboardTile(item: .previewItem)
        .padding()
}
