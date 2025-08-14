import SwiftUI
import Firebase

@main
struct Green_ThumbApp: App {
    init() { FirebaseApp.configure() }

    private let persistence = PersistenceController.shared
    @StateObject private var session = SessionStore()

    var body: some Scene {
        WindowGroup {
            AuthGateView()
                .environmentObject(session)
                .environment(\.managedObjectContext, persistence.context)
        }
    }
}
