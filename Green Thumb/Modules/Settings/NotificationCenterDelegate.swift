import Foundation
import UserNotifications

final class NotificationCenterDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationCenterDelegate()
    private override init() { super.init() }

    // Show banners while the app is in the foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .list, .sound])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        // Could route navigation based on response.notification.request.identifier
        completionHandler()
    }
}
