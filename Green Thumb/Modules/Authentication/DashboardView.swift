// Modules/Dashboard/Views/DashboardView.swift
import SwiftUI

// Lightweight placeholder used only inside Authentication flow previews/tests.
// Renamed to avoid clashing with the main Modules/Dashboard/DashboardView.
struct AuthPlaceholderDashboardView: View {
    var body: some View {
        NavigationStack {
            Text("Welcome to GreenThumb 🌿")
                .font(.title2)
                .padding()
                .navigationTitle("Dashboard")
        }
    }
}
