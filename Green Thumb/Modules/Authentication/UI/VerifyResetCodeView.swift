// Modules/Authentication/UI/VerifyResetCodeView.swift
import SwiftUI
import FirebaseAuth

struct VerifyResetCodeView: View {
    @State private var codeOrURL = ""
    @State private var isVerifying = false
    @State private var emailFromCode: String?
    @State private var verifiedCode: String?
    @State private var error: String?
    @State private var goToReset = false

    var body: some View {
        VStack(spacing: 16) {
            Image("Setting Setting")   // <- use the name you added in Assets.xcassets
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200) // adjust size as needed
                    .padding(.top, 40)
            
            Text("Verification").font(.title2).bold()
            Text("Paste the code or the full link you received by email.")
                .font(.footnote).foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            TextField("Paste code or URL", text: $codeOrURL)
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.never)

            Button {
                Task { await verify() }
            } label: {
                Text(isVerifying ? "Verifying..." : "Continue").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(codeOrURL.isEmpty || isVerifying)

            if let emailFromCode {
                Text("Code is for: \(emailFromCode)")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            if let error { Text(error).foregroundStyle(.red).font(.footnote).multilineTextAlignment(.center) }

            Spacer()
        }
        .padding()
        .navigationDestination(isPresented: $goToReset) {
            ResetPasswordView(oobCode: verifiedCode ?? "")
        }
        // Bonus: if the user opens the email link and it routes back to the app,
        // iOS will call onOpenURL; paste it automatically for the user.
        .onOpenURL { url in
            if let oc = Self.extractOobCode(from: url.absoluteString) {
                codeOrURL = oc
            }
        }
    }

    /// Convert technical Firebase errors to user-friendly messages
    private func userFriendlyErrorMessage(from error: Error) -> String {
        let errorDescription = error.localizedDescription.lowercased()
        
        if errorDescription.contains("invalid-action-code") || errorDescription.contains("expired") {
            return "The reset code has expired or is invalid. Please request a new one."
        } else if errorDescription.contains("malformed") {
            return "Please enter a valid reset code."
        } else if errorDescription.contains("network") {
            return "Please check your internet connection and try again."
        } else {
            return "Unable to verify reset code. Please try again or request a new one."
        }
    }

    private func verify() async {
        error = nil; isVerifying = true
        let code = Self.extractOobCode(from: codeOrURL) ?? codeOrURL
        do {
            let email = try await Auth.auth().verifyPasswordResetCode(code)
            self.verifiedCode = code
            self.emailFromCode = email
            self.goToReset = true
        } catch { self.error = userFriendlyErrorMessage(from: error) }
        isVerifying = false
    }

    static func extractOobCode(from text: String) -> String? {
        guard let comps = URLComponents(string: text) else { return nil }
        return comps.queryItems?.first(where: { $0.name == "oobCode" })?.value
    }
}


#Preview("VerifyResetCodeView") {
    VerifyResetCodeView()
        .environmentObject(SessionStore())          // if your view needs it
        .environmentObject(ColorSchemeController()) // if your app uses it
}
