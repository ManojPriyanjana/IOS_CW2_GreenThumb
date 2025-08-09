import SwiftUI

struct SignupView: View {
    @StateObject private var viewModel = AuthViewModel()
    @Environment(\.dismiss) var dismiss
    @State private var showSuccessAlert = false

    var body: some View {
        VStack(spacing: 20) {
            Text("Sign Up")
                .font(.title)

            TextField("Email", text: $viewModel.email)
                .autocapitalization(.none)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            SecureField("Password", text: $viewModel.password)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            Button("Create Account") {
                viewModel.signup {
                    showSuccessAlert = true
                }
            }
            .buttonStyle(.borderedProminent)

            Button("Cancel") {
                dismiss()
            }

            Text(viewModel.errorMessage)
                .foregroundColor(.red)
                .font(.footnote)
        }
        .padding()
        .alert("Account created successfully!", isPresented: $showSuccessAlert) {
            Button("OK") {
                dismiss() // Go back to LoginView
            }
        }
    }
}
