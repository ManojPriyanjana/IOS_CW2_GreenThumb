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
                    DashboardView()

                case .plants:
                    Text("Plants")
                        .font(.title)
                        .padding()

                case .stores:
                    Text("Nearby Stores")
                        .font(.title)
                        .padding()

                case .profile:
//                    Text("Profile")
//                        .font(.title)
//                        .padding()
                    TaskListView()

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
