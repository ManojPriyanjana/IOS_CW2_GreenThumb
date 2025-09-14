import SwiftUI

/// App-wide fixed top bar with gradient background.
struct AppTopBar: View {
    var body: some View {
        ZStack(alignment: .bottom) {
            // Gradient covers the status bar / Dynamic Island area
            LinearGradient(colors: [Color.green.opacity(0.95), Color.teal.opacity(0.95)],
                           startPoint: .topLeading, endPoint: .topTrailing)
                .ignoresSafeArea(edges: .top)

            VStack(spacing: 0) {
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "leaf.fill")
                            .font(.title2)
                            .foregroundStyle(.white)
                        Text("GreenThumb")
                            .font(.title3).bold()
                            .foregroundStyle(.white)
                    }
                    Spacer()
                    HStack(spacing: 10) {
                        TopBarCircleIcon(system: "magnifyingglass")
                        TopBarCircleIcon(system: "bell")
                        TopBarCircleIcon(system: "person.crop.circle")
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 10)

                Divider().background(Color.white.opacity(0.15))
            }
        }
    }
}

private struct TopBarCircleIcon: View {
    let system: String
    var body: some View {
        Button {} label: {
            Image(systemName: system)
                .font(.subheadline)
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(Color.white.opacity(0.18))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    AppTopBar()
}
