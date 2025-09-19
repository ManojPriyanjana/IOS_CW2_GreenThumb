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
                .navigationTitle(greetingTitle)
        }
    }
}

private extension AuthPlaceholderDashboardView {
    var greetingTitle: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:  return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default:      return "Good night"
        }
    }
}
