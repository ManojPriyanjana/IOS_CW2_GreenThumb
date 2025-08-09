import SwiftUI
import Firebase  //Required to access FirebaseApp

@main
struct Green_ThumbApp: App {
    
    // This runs when app starts
    init() {
        FirebaseApp.configure()  //This fixes the crash
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
