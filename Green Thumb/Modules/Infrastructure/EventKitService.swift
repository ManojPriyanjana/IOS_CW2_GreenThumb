import Foundation
import EventKit

/// Minimal scaffold for future EventKit integration.
/// Not referenced anywhere yet to avoid side-effects.
final class EventKitService {
    static let shared = EventKitService()
    private let store = EKEventStore()
    private let mappingKey = "ReminderIDByTaskURI"
    private let calMappingKey = "EventIDByScheduleURI"

    private init() {}

    // Explicit requesters to be called when wiring features
    func requestRemindersAccess(completion: @escaping (Bool) -> Void) {
        store.requestAccess(to: .reminder) { granted, _ in
            DispatchQueue.main.async { completion(granted) }
        }
    }

    func requestCalendarAccess(completion: @escaping (Bool) -> Void) {
        store.requestAccess(to: .event) { granted, _ in
            DispatchQueue.main.async { completion(granted) }
        }
    }

    enum EKServiceError: Error { case denied, noCalendar, saveFailed, unknown }

    /// Create or update a Reminder for a given task key (e.g., Core Data object URI string).
    /// Stores the reminder identifier for idempotency.
    func createOrUpdateReminder(taskKey: String,
                                title: String,
                                due: Date?,
                                notes: String?,
                                completion: @escaping (Result<Void, Error>) -> Void) {
        let status = EKEventStore.authorizationStatus(for: .reminder)
        switch status {
        case .authorized:
            self.upsertReminder(taskKey: taskKey, title: title, due: due, notes: notes, completion: completion)
        case .notDetermined:
            requestRemindersAccess { granted in
                if granted {
                    self.upsertReminder(taskKey: taskKey, title: title, due: due, notes: notes, completion: completion)
                } else {
                    completion(.failure(EKServiceError.denied))
                }
            }
        default:
            completion(.failure(EKServiceError.denied))
        }
    }

    private func upsertReminder(taskKey: String,
                                title: String,
                                due: Date?,
                                notes: String?,
                                completion: @escaping (Result<Void, Error>) -> Void) {
        var reminder: EKReminder?

        // Try load existing by identifier
        if let existingID = mapping()[taskKey],
           let item = store.calendarItem(withIdentifier: existingID) as? EKReminder {
            reminder = item
        }

        if reminder == nil {
            reminder = EKReminder(eventStore: store)
            // Choose a writable reminders calendar
            if let cal = store.defaultCalendarForNewReminders() ?? store.calendars(for: .reminder).first(where: { $0.allowsContentModifications }) {
                reminder?.calendar = cal
            } else {
                completion(.failure(EKServiceError.noCalendar)); return
            }
        }

        guard let r = reminder else { completion(.failure(EKServiceError.unknown)); return }

        r.title = title.isEmpty ? "Task" : title
        r.notes = notes
        if let due {
            let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: due)
            r.dueDateComponents = comps
            // Optional: add an alarm
            r.alarms = [EKAlarm(absoluteDate: due)]
        } else {
            r.dueDateComponents = nil
            r.alarms = nil
        }

        do {
            try store.save(r, commit: true)
            var map = mapping()
            map[taskKey] = r.calendarItemIdentifier
            saveMapping(map)
            completion(.success(()))
        } catch {
            completion(.failure(EKServiceError.saveFailed))
        }
    }

    // MARK: - Mapping persistence
    private func mapping() -> [String: String] {
        (UserDefaults.standard.dictionary(forKey: mappingKey) as? [String: String]) ?? [:]
    }
    private func saveMapping(_ map: [String: String]) {
        UserDefaults.standard.set(map, forKey: mappingKey)
    }

    // MARK: - Calendar (Harvest)
    func createOrUpdateEvent(scheduleKey: String,
                             title: String,
                             start: Date?,
                             end: Date?,
                             notes: String?,
                             completion: @escaping (Result<Void, Error>) -> Void) {
        let status = EKEventStore.authorizationStatus(for: .event)
        switch status {
        case .authorized:
            upsertEvent(scheduleKey: scheduleKey, title: title, start: start, end: end, notes: notes, completion: completion)
        case .notDetermined:
            requestCalendarAccess { granted in
                if granted { self.upsertEvent(scheduleKey: scheduleKey, title: title, start: start, end: end, notes: notes, completion: completion) }
                else { completion(.failure(EKServiceError.denied)) }
            }
        default:
            completion(.failure(EKServiceError.denied))
        }
    }

    private func upsertEvent(scheduleKey: String,
                             title: String,
                             start: Date?,
                             end: Date?,
                             notes: String?,
                             completion: @escaping (Result<Void, Error>) -> Void) {
        var event: EKEvent?
        if let existingID = (UserDefaults.standard.dictionary(forKey: calMappingKey) as? [String: String])?[scheduleKey],
           let item = store.event(withIdentifier: existingID) {
            event = item
        }
        if event == nil { event = EKEvent(eventStore: store) }

        guard let e = event else { completion(.failure(EKServiceError.unknown)); return }

        e.title = title.isEmpty ? "Harvest" : title
        e.notes = notes
        if let start { e.startDate = start } else { e.startDate = Date() }
        if let end { e.endDate = end } else { e.endDate = e.startDate.addingTimeInterval(3600) }
        e.calendar = store.defaultCalendarForNewEvents

        do {
            try store.save(e, span: .thisEvent, commit: true)
            var map = (UserDefaults.standard.dictionary(forKey: calMappingKey) as? [String: String]) ?? [:]
            map[scheduleKey] = e.eventIdentifier
            UserDefaults.standard.set(map, forKey: calMappingKey)
            completion(.success(()))
        } catch {
            completion(.failure(EKServiceError.saveFailed))
        }
    }
}
