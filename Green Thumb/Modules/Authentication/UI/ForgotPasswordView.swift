// Modules/Authentication/UI/ForgotPasswordView.swift
import SwiftUI
import FirebaseAuth

struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var isSending = false
    @State private var error: String?
    @State private var goToVerify = false

    var body: some View {
        VStack(spacing: 16) {
            
            Image("fogetPassword")   // <- use the name you added in Assets.xcassets
                    .resizable()
                    .scaledToFit()
                    .frame(width: 250, height: 250) // adjust size as needed
                    .padding(.top, 40)
            
            
            Text("Forgot Password?")
                .font(.title2).bold()

            TextField("Email Address", text: $email)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
                .textFieldStyle(.roundedBorder)

            Button {
                Task { await sendEmail() }
            } label: {
                Text(isSending ? "Sending..." : "Send Code")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isSending || email.isEmpty)

            if let error { Text(error).foregroundStyle(.red).font(.footnote).multilineTextAlignment(.center) }

            Spacer()
        }
        .padding()
        .navigationDestination(isPresented: $goToVerify) {
            VerifyResetCodeView()
        }
    }

    @MainActor
    /// Convert technical Firebase errors to user-friendly messages
    private func userFriendlyErrorMessage(from error: Error) -> String {
        let errorDescription = error.localizedDescription.lowercased()
        
        if errorDescription.contains("invalid-email") {
            return "Please enter a valid email address."
        } else if errorDescription.contains("user-not-found") {
            return "No account found with this email address."
        } else if errorDescription.contains("too-many-requests") {
            return "Too many requests. Please try again later."
        } else if errorDescription.contains("network") {
            return "Please check your internet connection and try again."
        } else {
            return "Unable to send reset email. Please try again."
        }
    }

    private func sendEmail() async {
        error = nil; isSending = true
        do {
            // Standard Firebase: sends an email with a reset link that includes oobCode
            try await Auth.auth().sendPasswordReset(withEmail: email)
            goToVerify = true
        } catch { self.error = userFriendlyErrorMessage(from: error) }
        isSending = false
    }
}

#Preview("ForgotPasswordView") {
    NavigationStack {
        ForgotPasswordView()
            .environmentObject(SessionStore())          // only if needed
            .environmentObject(ColorSchemeController())  // only if used
    }
}
