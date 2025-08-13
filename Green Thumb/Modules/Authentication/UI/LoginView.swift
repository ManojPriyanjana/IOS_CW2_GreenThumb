import SwiftUI

struct LoginView: View {
    @EnvironmentObject var session: SessionStore
    @StateObject private var vm = AuthViewModel()
    @State private var showSignup = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Green Thumb").font(.largeTitle).bold()

                TextField("Email", text: $vm.email)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .textFieldStyle(.roundedBorder)

                SecureField("Password", text: $vm.password)
                    .textFieldStyle(.roundedBorder)

                if BiometricAuth.kind() != .none {
                    Toggle("Enable Face ID / Touch ID", isOn: $vm.wantsBiometrics)
                }

                Button {
                    Task {
                        vm.isBusy = true
                        await session.signIn(email: vm.email, password: vm.password)
                        session.setBiometricsEnabled(vm.wantsBiometrics)
                        vm.isBusy = false
                    }
                } label: {
                    Text(vm.isBusy ? "Signing In…" : "Sign In").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(vm.isBusy || vm.email.isEmpty || vm.password.isEmpty)

                Button("Create an account") { showSignup = true }
                    .padding(.top, 8)

                if let err = session.errorMessage {
                    Text(err).foregroundStyle(.red).font(.footnote).multilineTextAlignment(.center)
                }

                Spacer()
            }
            .padding()
            .navigationDestination(isPresented: $showSignup) { SignupView() }
        }
    }
}
