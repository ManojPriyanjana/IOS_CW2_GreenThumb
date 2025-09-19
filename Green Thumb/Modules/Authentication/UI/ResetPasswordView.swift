// Modules/Authentication/UI/ResetPasswordView.swift
import SwiftUI
import FirebaseAuth

struct ResetPasswordView: View {
    let oobCode: String
    @Environment(\.dismiss) private var dismiss

    @State private var password = ""
    @State private var confirm = ""
    @State private var isResetting = false
    @State private var error: String?
    @State private var done = false

    var body: some View {
        VStack(spacing: 16) {
            
            Image("Password Reset")   // <- use the name you added in Assets.xcassets
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200) // adjust size as needed
                    .padding(.top, 40)
            
            Text("Set New Password").font(.title2).bold()

            SecureField("New Password", text: $password)
                .textFieldStyle(.roundedBorder)
            SecureField("Confirm Password", text: $confirm)
                .textFieldStyle(.roundedBorder)

            Button {
                Task { await reset() }
            } label: {
                Text(isResetting ? "Resetting..." : "Reset Password")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isResetting || !canSubmit)

            if let error { Text(error).foregroundStyle(.red).font(.footnote).multilineTextAlignment(.center) }

            Spacer()
        }
        .padding()
        .navigationDestination(isPresented: $done) {
            PasswordChangedSuccessView()
        }
    }

    private var canSubmit: Bool {
        !password.isEmpty && password == confirm && password.count >= 6
    }

    /// Convert technical Firebase errors to user-friendly messages
    private func userFriendlyErrorMessage(from error: Error) -> String {
        let errorDescription = error.localizedDescription.lowercased()
        
        if errorDescription.contains("malformed") || errorDescription.contains("expired") {
            return "The password reset link has expired. Please request a new one."
        } else if errorDescription.contains("invalid-action-code") {
            return "The password reset link is invalid. Please request a new one."
        } else if errorDescription.contains("weak-password") {
            return "Please choose a stronger password (at least 6 characters)."
        } else if errorDescription.contains("network") {
            return "Please check your internet connection and try again."
        } else {
            return "Unable to reset password. Please try again or request a new reset link."
        }
    }

    private func reset() async {
        error = nil; isResetting = true
        do {
            try await Auth.auth().confirmPasswordReset(withCode: oobCode, newPassword: password)
            done = true
        } catch { self.error = userFriendlyErrorMessage(from: error) }
        isResetting = false
    }
}

#Preview("Reset Password") {
    ResetPasswordView(oobCode: "PREVIEW-OOB-CODE")
        .environmentObject(SessionStore())          // if your view needs it
        .environmentObject(ColorSchemeController())  // if your app uses it
}
