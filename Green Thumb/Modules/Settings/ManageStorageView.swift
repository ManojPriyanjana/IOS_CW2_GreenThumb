import SwiftUI

struct ManageStorageView: View {
    @State private var usage = "Calculating…"

    var body: some View {
        List {
            HStack { Text("App Data Usage"); Spacer(); Text(usage).foregroundStyle(.secondary) }
            Button("Clear Cached Images") {
                // TODO: clear caches
                usage = "Cleared"
            }
            Button("Export Backup") {
                // TODO: export JSON/CoreData backup
            }
        }
        .navigationTitle("Manage Storage")
        .onAppear { estimate() }
    }

    private func estimate() {
        DispatchQueue.main.asyncAfter(deadline: .now()+0.4) { usage = "512 MB used" }
    }
}
