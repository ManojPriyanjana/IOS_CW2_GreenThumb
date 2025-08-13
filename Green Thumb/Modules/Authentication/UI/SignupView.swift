import SwiftUI

struct SignupView: View {
    @EnvironmentObject var session: SessionStore
    @StateObject private var vm = AuthViewModel()

    var body: some View {
        VStack(spacing: 16) {
            Text("Create Account").font(.title).bold()

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
                    await session.signUp(email: vm.email, password: vm.password)
                    session.setBiometricsEnabled(vm.wantsBiometrics)
                    vm.isBusy = false
                }
            } label: {
                Text(vm.isBusy ? "Creating…" : "Sign Up").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(vm.isBusy || vm.email.isEmpty || vm.password.isEmpty)

            if let err = session.errorMessage {
                Text(err).foregroundStyle(.red).font(.footnote).multilineTextAlignment(.center)
            }

            Spacer()
        }
        .padding()
    }
}
