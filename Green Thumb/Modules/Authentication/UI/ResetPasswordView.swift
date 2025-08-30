// Modules/Authentication/UI/ResetPasswordView.swift
import SwiftUI
import FirebaseAuth

struct ResetPasswordView: View {
    let oobCode: String

    @State private var password = ""
    @State private var confirm = ""
    @State private var isResetting = false
    @State private var error: String?
    @State private var done = false

    var body: some View {
        VStack(spacing: 16) {
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

    private func reset() async {
        error = nil; isResetting = true
        do {
            try await Auth.auth().confirmPasswordReset(withCode: oobCode, newPassword: password)
            done = true
        } catch { self.error = error.localizedDescription }
        isResetting = false
    }
}
