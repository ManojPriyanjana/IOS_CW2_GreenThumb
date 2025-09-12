import Foundation
import UserNotifications

final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    private override init() { super.init() }

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

    // MARK: - Scheduling helpers

    /// Schedule a local notification at a specific date/time.
    /// If the provided date is in the past, it fires in ~5 seconds.
    func schedule(id: String, title: String, body: String, at date: Date, completion: ((Error?) -> Void)? = nil) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let fire = max(date.timeIntervalSinceNow, 5) // never immediate
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: fire, repeats: false)
        let req = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(req) { err in
            DispatchQueue.main.async { completion?(err) }
        }
    }

    /// Schedule a one-off notification at a specific calendar date/time.
    func scheduleOnce(id: String, title: String, body: String, at date: Date, completion: ((Error?) -> Void)? = nil) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        var comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        // If in the past, fallback to ~5s from now using time interval
        if let d = Calendar.current.date(from: comps), d.timeIntervalSinceNow < 5 {
            return schedule(id: id, title: title, body: body, at: Date().addingTimeInterval(5), completion: completion)
        }
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let req = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(req) { err in
            DispatchQueue.main.async { completion?(err) }
        }
    }

    /// Schedule a repeating daily notification at hour:minute local time.
    func scheduleDaily(id: String, title: String, body: String, hour: Int, minute: Int, completion: ((Error?) -> Void)? = nil) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        var comps = DateComponents()
        comps.hour = hour
        comps.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        let req = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(req) { err in
            DispatchQueue.main.async { completion?(err) }
        }
    }

    /// Schedule a repeating weekly notification on a given weekday at hour:minute.
    /// weekday follows Calendar.current: 1 = Sunday ... 7 = Saturday
    func scheduleWeekly(id: String, title: String, body: String, weekday: Int, hour: Int, minute: Int, completion: ((Error?) -> Void)? = nil) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        var comps = DateComponents()
        comps.weekday = weekday
        comps.hour = hour
        comps.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        let req = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(req) { err in
            DispatchQueue.main.async { completion?(err) }
        }
    }

    /// Schedule a repeating monthly notification on a given day-of-month at hour:minute.
    /// Note: If a month lacks the specified day (e.g., 31), the system may skip that month.
    func scheduleMonthly(id: String, title: String, body: String, day: Int, hour: Int, minute: Int, completion: ((Error?) -> Void)? = nil) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        var comps = DateComponents()
        comps.day = max(1, min(day, 31))
        comps.hour = hour
        comps.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        let req = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(req) { err in
            DispatchQueue.main.async { completion?(err) }
        }
    }

    /// Cancel a previously scheduled notification.
    func cancel(id: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }

    // MARK: - Diagnostics

    /// Print current authorization and pending requests to help debug flaky notifications.
    func debugLogState(reason: String = "") {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            center.getPendingNotificationRequests { pending in
                #if DEBUG
                print("[Notifications] State", reason.isEmpty ? "" : "(\(reason))",
                      "status=\(settings.authorizationStatus.rawValue)",
                      "sound=\(settings.soundSetting.rawValue)",
                      "alert=\(settings.alertSetting.rawValue)",
                      "badge=\(settings.badgeSetting.rawValue)",
                      "pending=\(pending.count)")
                for r in pending.prefix(10) { // cap output
                    print("  • id=\(r.identifier) title=\(r.content.title) trigger=\(String(describing: r.trigger))")
                }
                #endif
            }
        }
    }

    // MARK: - UNUserNotificationCenterDelegate

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .list, .sound])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        completionHandler()
    }
}
