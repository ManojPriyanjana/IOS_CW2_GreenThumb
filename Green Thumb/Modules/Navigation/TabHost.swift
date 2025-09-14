import SwiftUI

/// Root container that shows the current tab's content + the bottom bar.
struct TabHost: View {
    @State private var selected: AppTab = .dashboard

    var body: some View {
        ZStack(alignment: .bottom) {
            // MAIN CONTENT
            Group {
                switch selected {
                case .dashboard:
                    NavigationStack { DashboardView() }

                case .plants:
                    Text("Plants")
//                        .font(.title)
//                        .padding()
                        PlantListView()

                case .stores:
                    NavigationStack { StoreLocatorView(initialQuery: nil) }

                case .profile:
                    Text("Profile")
//                        .font(.title)
//                        .padding()
                          
                case.tasks:
                    NavigationStack { AllTasksView() }

                case .settings:
                    SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(UIColor.systemGroupedBackground))

            // BOTTOM BAR
            CustomTabBar(selected: $selected)
        }
        // Correct API
        .ignoresSafeArea(edges: .bottom)
        .ignoresSafeArea(.keyboard, edges: .bottom) // optional: keep bar when keyboard shows
    }
}

// MARK: - Global App Top Bar (inline to ensure target membership)
private struct AppTopBar: View {
    var body: some View {
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
        .frame(maxWidth: .infinity, alignment: .bottom)
        .background(
            LinearGradient(colors: [Color.green.opacity(0.95), Color.teal.opacity(0.95)],
                           startPoint: .topLeading, endPoint: .topTrailing)
                .ignoresSafeArea(edges: .top)
        )
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
