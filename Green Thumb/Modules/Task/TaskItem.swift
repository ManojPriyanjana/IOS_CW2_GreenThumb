import Foundation

enum TaskType: Int16, CaseIterable, Identifiable {
    case watering = 0, fertilizing, pruning, repotting, healthCheck
    var id: Int16 { rawValue }
    var label: String {
        switch self {
        case .watering: return "Watering"
        case .fertilizing: return "Fertilizing"
        case .pruning: return "Pruning"
        case .repotting: return "Repotting"
        case .healthCheck: return "Health Check"
        }
    }
    var systemImage: String {
        switch self {
        case .watering: return "drop.fill"
        case .fertilizing: return "leaf.fill"
        case .pruning: return "scissors"
        case .repotting: return "arrow.2.circlepath"
        case .healthCheck: return "heart.text.square.fill"
        }
    }
}

enum RepeatUnit: Int16, CaseIterable { case day = 0, week = 1, month = 2 }

struct RecurrenceRule: Equatable {
    var every: Int
    var unit: RepeatUnit
    static let none = RecurrenceRule(every: 0, unit: .day)

    func nextOccurrences(starting from: Date, count: Int) -> [Date] {
        guard every > 0, count > 0 else { return [] }
        var out: [Date] = []
        var date = from
        let cal = Calendar.current
        for _ in 0..<count {
            switch unit {
            case .day:   date = cal.date(byAdding: .day, value: every, to: date) ?? date
            case .week:  date = cal.date(byAdding: .weekOfYear, value: every, to: date) ?? date
            case .month: date = cal.date(byAdding: .month, value: every, to: date) ?? date
            }
            out.append(date)
        }
        return out
    }
}

struct TaskItem: Identifiable, Equatable {
    var id: UUID = .init()
    var title: String
    var notes: String?
    var type: TaskType
    var priority: Int = 0
    var startDate: Date?
    var dueDate: Date?
    var remindAt: Date?
    var isCompleted: Bool = false
    var isWeatherAware: Bool = false
    var recurrence: RecurrenceRule = .none
    var plantId: UUID?
    var createdAt: Date = .init()
    var updatedAt: Date = .init()
}

enum TaskFilter { case all, today, upcoming, overdue, done, health }
