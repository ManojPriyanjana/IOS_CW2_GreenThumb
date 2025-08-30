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
    private func sendEmail() async {
        error = nil; isSending = true
        do {
            // Standard Firebase: sends an email with a reset link that includes oobCode
            try await Auth.auth().sendPasswordReset(withEmail: email)
            goToVerify = true
        } catch { self.error = error.localizedDescription }
        isSending = false
    }
}


