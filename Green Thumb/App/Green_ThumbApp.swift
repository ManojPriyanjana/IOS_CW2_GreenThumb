//import SwiftUI
//import Firebase  //Required to access FirebaseApp
//
//@main
//struct Green_ThumbApp: App {
//    
//    // This runs when app starts
//    init() {
//        FirebaseApp.configure()  //This fixes the crash
//    }
//
//    var body: some Scene {
//        WindowGroup {
//            ContentView()
//        }
//    }
//}

import SwiftUI
import Firebase

@main
struct Green_ThumbApp: App {
    init() { FirebaseApp.configure() }

    @StateObject private var session = SessionStore()

    var body: some Scene {
        WindowGroup {
            AuthGateView()               // <- THIS must be the root
                .environmentObject(session)
        }
    }
}
