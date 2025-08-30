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

    private func verify() async {
        error = nil; isVerifying = true
        let code = Self.extractOobCode(from: codeOrURL) ?? codeOrURL
        do {
            let email = try await Auth.auth().verifyPasswordResetCode(code)
            self.verifiedCode = code
            self.emailFromCode = email
            self.goToReset = true
        } catch { self.error = error.localizedDescription }
        isVerifying = false
    }

    static func extractOobCode(from text: String) -> String? {
        guard let comps = URLComponents(string: text) else { return nil }
        return comps.queryItems?.first(where: { $0.name == "oobCode" })?.value
    }
}
