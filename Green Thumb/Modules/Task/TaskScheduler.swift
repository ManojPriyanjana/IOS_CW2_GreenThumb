// Modules/Task/TaskScheduler.swift
import Foundation
import UserNotifications

protocol TaskSchedulerProtocol {
    func requestPermission() async throws
    func scheduleReminder(for task: TaskItem) async throws
    func cancelReminder(for taskId: UUID)
}

final class TaskScheduler: TaskSchedulerProtocol {
    private let center = UNUserNotificationCenter.current()

    func requestPermission() async throws {
        let ok = try await center.requestAuthorization(options: [.alert, .sound, .badge])
        if !ok { throw NSError(domain: "TaskScheduler", code: 1,
                               userInfo: [NSLocalizedDescriptionKey: "Notifications not allowed"]) }
    }

    func scheduleReminder(for task: TaskItem) async throws {
        guard let date = task.remindAt else { return }
        let comps = Calendar.current.dateComponents([.year,.month,.day,.hour,.minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)

        let content = UNMutableNotificationContent()
        content.title = task.title
        content.subtitle = task.type.label
        content.body = (task.notes?.isEmpty == false ? task.notes! : "Care task due")
        content.sound = .default

        let req = UNNotificationRequest(identifier: task.id.uuidString,
                                        content: content, trigger: trigger)
        try await center.add(req)
    }

    func cancelReminder(for taskId: UUID) {
        center.removePendingNotificationRequests(withIdentifiers: [taskId.uuidString])
    }
}
