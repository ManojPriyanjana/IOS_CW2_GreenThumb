import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel = AuthViewModel()
    @State private var showSignup = false

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Green Thumb")
                    .font(.largeTitle)
                    .bold()

                TextField("Email", text: $viewModel.email)
                    .autocapitalization(.none)
                    .textFieldStyle(.roundedBorder)

                SecureField("Password", text: $viewModel.password)
                    .textFieldStyle(.roundedBorder)

                Button("Login") {
                    viewModel.login()
                }
                .buttonStyle(.borderedProminent)

                Button("Use Face ID") {
                    viewModel.useFaceID()
                }

                Button("Don't have an account? Sign Up") {
                    showSignup = true
                }

                Text(viewModel.errorMessage)
                    .foregroundColor(.red)
                    .font(.footnote)
            }
            .padding()
            .fullScreenCover(isPresented: $viewModel.isAuthenticated) {
                DashboardView()
            }
            .sheet(isPresented: $showSignup) {
                SignupView()
            }
        }
    }
}
