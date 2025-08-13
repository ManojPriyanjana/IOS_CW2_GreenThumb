//
//import SwiftUI
//
//struct ContentView: View {
//    var body: some View {
//        DashboardView()
////        LoginView()
//    }
//}
//
//#Preview {
////    LoginView()
////    ContentView()
//}

import SwiftUI

struct ContentView: View {
    var body: some View {
        AuthGateView()                  // <- NOT DashboardView()
    }
}

#Preview {
    ContentView().environmentObject(SessionStore())
}

