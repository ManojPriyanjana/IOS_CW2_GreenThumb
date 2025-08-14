import Foundation
import UserNotifications
import CoreData

final class ReminderScheduler {
    static let shared = ReminderScheduler()

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in }
    }

    func schedule(task: CareTask, plantName: String) {
        guard let due = task.dueDate as Date?,
              task.isCompleted == false else { return }

        let content = UNMutableNotificationContent()
        content.title = "Care due: \(plantName)"
        content.body = body(for: task)
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: Calendar.current.dateComponents([.year,.month,.day,.hour,.minute], from: due), repeats: false)
        let req = UNNotificationRequest(identifier: task.id?.uuidString ?? UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(req, withCompletionHandler: nil)
    }

    private func body(for task: CareTask) -> String {
        switch task.type ?? "" {
        case CareType.water.rawValue: return "Time to water your plant."
        case CareType.fertilize.rawValue: return "Time to fertilize."
        case CareType.prune.rawValue: return "Consider a light prune."
        case CareType.repot.rawValue: return "Check if it needs a new pot."
        default: return "Care task due."
        }
    }
}
