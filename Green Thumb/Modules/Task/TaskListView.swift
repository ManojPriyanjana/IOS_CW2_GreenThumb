import SwiftUI

struct TaskListView: View {
    @StateObject private var vm = TaskListViewModel()
    @State private var showEditor = false

    var body: some View {
        NavigationView {
            VStack(spacing: 8) {
                Picker("", selection: $vm.filter) {
                    Text("All").tag(TaskFilter.all)
                    Text("Done").tag(TaskFilter.done)
                    Text("Health").tag(TaskFilter.health)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                TextField("Search tasks…", text: $vm.search)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)

                List {
                    ForEach(vm.tasks) { item in
                        TaskRowView(item: item) { vm.toggleComplete(item) }
                            .listRowSeparator(.hidden)
                    }
                    .onDelete(perform: vm.delete)
                }
                .listStyle(.plain)
            }
            .navigationTitle("Tasks & Log")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showEditor = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showEditor, onDismiss: { Task { await vm.refresh() } }) {
                TaskEditorView()
            }
        }
        //Re-fetch whenever the filter or search text changes
        .task(id: vm.filter) { await vm.refresh() }
        .task(id: vm.search) { await vm.refresh() }
    }
}
