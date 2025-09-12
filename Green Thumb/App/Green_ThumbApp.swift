import SwiftUI
import Firebase
import UserNotifications

@MainActor
final class ColorSchemeController: ObservableObject {
    @Published var override: ColorScheme? = nil
    func apply(darkModeEnabled: Bool) { override = darkModeEnabled ? .dark : nil }
}

@main
struct Green_ThumbApp: App {
    init() {
        FirebaseApp.configure()
    UNUserNotificationCenter.current().delegate = NotificationManager.shared
    }

    private let persistence = PersistenceController.shared
    @StateObject private var session = SessionStore()
    @StateObject private var colorCtl = ColorSchemeController()
    private let settingsStore = UserDefaultsSettingsStore()

    var body: some Scene {
        WindowGroup {
            AuthGateView()
                .environmentObject(session)
                .environment(\.managedObjectContext, persistence.context)
                .environmentObject(colorCtl)
                .preferredColorScheme(colorCtl.override)
                .task {
                    let settings = settingsStore.load()
                    colorCtl.apply(darkModeEnabled: settings.darkModeEnabled)
                    #if DEBUG
                    NotificationManager.shared.debugLogState(reason: "app-start")
                    #endif
                }
        }
    }
}
