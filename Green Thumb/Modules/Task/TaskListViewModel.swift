import Foundation

@MainActor
final class TaskListViewModel: ObservableObject {
    @Published var tasks: [TaskItem] = []
    @Published var filter: TaskFilter = .all
    @Published var search: String = ""

    private let repo: TaskRepositoryProtocol

    init(repo: TaskRepositoryProtocol = TaskRepository()) {
        self.repo = repo
        Task { await refresh() }
    }

    func refresh() async {
        do {
            var items = try repo.fetch(filter)
            if !search.isEmpty {
                items = items.filter { $0.title.localizedCaseInsensitiveContains(search) ||
                    ($0.notes ?? "").localizedCaseInsensitiveContains(search) }
            }
            tasks = items
        } catch {
            print("TaskList refresh error: \(error)")
        }
    }

    func toggleComplete(_ item: TaskItem) {
        var t = item
        t.isCompleted.toggle()
        try? repo.upsert(t)
        Task { await refresh() }
    }

    func delete(at offsets: IndexSet) {
        let ids = offsets.map { tasks[$0].id }
        try? repo.delete(ids: ids)
        Task { await refresh() }
    }
}
