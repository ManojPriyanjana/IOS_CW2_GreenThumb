// Modules/Task/TaskEditorViewModel.swift
import Foundation

@MainActor
final class TaskEditorViewModel: ObservableObject {
    @Published var item: TaskItem
    @Published var nextOccurrences: [Date] = []

    private let repo: TaskRepositoryProtocol
    private let scheduler: TaskSchedulerProtocol

    init(existing: TaskItem? = nil,
         repo: TaskRepositoryProtocol = TaskRepository(),
         scheduler: TaskSchedulerProtocol = TaskScheduler()) {
        self.item = existing ?? TaskItem(title: "Watering", notes: nil, type: .watering)
        self.repo = repo
        self.scheduler = scheduler
        recomputeOccurrences()
    }

    func save() async -> Bool {
        do {
            try repo.upsert(item)
            if item.remindAt != nil {
                try await scheduler.requestPermission()
                try await scheduler.scheduleReminder(for: item)
            }
            recomputeOccurrences()
            return true
        } catch {
            print("Save error: \(error)")
            return false
        }
    }

    func recomputeOccurrences() {
        guard item.recurrence.every > 0,
              let start = item.startDate ?? item.dueDate else { nextOccurrences = []; return }
        nextOccurrences = item.recurrence.nextOccurrences(starting: start, count: 3)
    }
}

//  Created by Dayasri 007 on 2025-08-15.
//

