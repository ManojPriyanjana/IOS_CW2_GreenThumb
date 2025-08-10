import Foundation
import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager(); private init() {}

    func requestAuth(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .badge, .sound]) { ok, _ in
                DispatchQueue.main.async { completion(ok) }
            }
    }

    func isWithinQuietHours(date: Date, start: Int, end: Int) -> Bool {
        let cal = Calendar.current
        let secs = cal.component(.hour, from: date) * 3600 + cal.component(.minute, from: date) * 60
        if start <= end { return secs >= start && secs < end }
        return secs >= start || secs < end // overnight (e.g., 21:00–07:00)
    }
}
