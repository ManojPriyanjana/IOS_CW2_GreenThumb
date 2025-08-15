import SwiftUI

struct AuthGateView: View {
    @EnvironmentObject var session: SessionStore

    var body: some View {
        Group {
            switch session.phase {
            case .loading:
                ProgressView("Loading…")
            case .loggedOut:
                LoginView()
            case .locked:
                LockView()
            case .authenticated:
//                DashboardView()   // real app entry
                  TabHost()
            }
        }
        .animation(.default, value: session.phase)
    }
}
