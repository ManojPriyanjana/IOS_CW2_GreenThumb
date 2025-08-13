// Modules/Authentication/Views/SignupView.swift
import SwiftUI

struct SignupView: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Sign Up placeholder")
                Button("Close") { dismiss() }
            }
            .padding()
            .navigationTitle("Sign Up")
        }
    }
}
