//import SwiftUI
//
//struct SignupView: View {
//    @EnvironmentObject var session: SessionStore
//    @StateObject private var vm = AuthViewModel()
//
//    var body: some View {
//        VStack(spacing: 16) {
//            Text("Create Account").font(.title).bold()
//
//            TextField("Email", text: $vm.email)
//                .textInputAutocapitalization(.never)
//                .keyboardType(.emailAddress)
//                .textFieldStyle(.roundedBorder)
//
//            SecureField("Password", text: $vm.password)
//                .textFieldStyle(.roundedBorder)
//
//            if BiometricAuth.kind() != .none {
//                Toggle("Enable Face ID / Touch ID", isOn: $vm.wantsBiometrics)
//            }
//
//            Button {
//                Task {
//                    vm.isBusy = true
//                    await session.signUp(email: vm.email, password: vm.password)
//                    session.setBiometricsEnabled(vm.wantsBiometrics)
//                    vm.isBusy = false
//                }
//            } label: {
//                Text(vm.isBusy ? "Creating…" : "Sign Up").frame(maxWidth: .infinity)
//            }
//            .buttonStyle(.borderedProminent)
//            .disabled(vm.isBusy || vm.email.isEmpty || vm.password.isEmpty)
//
//            if let err = session.errorMessage {
//                Text(err).foregroundStyle(.red).font(.footnote).multilineTextAlignment(.center)
//            }
//
//            Spacer()
//        }
//        .padding()
//    }
//}

import SwiftUI

struct SignupView: View {
    @EnvironmentObject var session: SessionStore
    @StateObject private var vm = AuthViewModel()
    @Environment(\.dismiss) private var dismiss
    
    @State private var confirmPassword = ""
    @State private var agreedPolicy = false

    var body: some View {
        VStack(spacing: 16) {
            
            Image("signup")   // Same logo as LoginView
                .resizable()
                .scaledToFit()
                .frame(width: 280, height: 280) // Same size as LoginView
                .padding(.top, 40)
            
            Text("Green Thumb").font(.largeTitle).bold() // Same title as LoginView

            TextField("Email", text: $vm.email)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress) // helps AutoFill and avoids odd overlays
                .textFieldStyle(.roundedBorder) // Same style as LoginView

            SecureField("Password", text: $vm.password)
#if DEBUG
#if targetEnvironment(simulator)
                .textContentType(nil) // avoid Simulator yellow "Automatic Strong Password" debug overlay
#else
                .textContentType(.newPassword)
#endif
#else
                .textContentType(.newPassword)
#endif
                .textFieldStyle(.roundedBorder) // Same style as LoginView

            SecureField("Confirm Password", text: $confirmPassword)
#if DEBUG
#if targetEnvironment(simulator)
                .textContentType(nil) // avoid Simulator yellow overlay for confirm field too
#else
                .textContentType(.newPassword)
#endif
#else
                .textContentType(.newPassword)
#endif
                .textFieldStyle(.roundedBorder) // Same style as LoginView

            // Privacy policy toggle - simplified to match LoginView style
            Toggle("I agree with privacy policy", isOn: $agreedPolicy)

            if BiometricAuth.kind() != .none {
                Toggle("Enable Face ID / Touch ID", isOn: $vm.wantsBiometrics)
            }

            Button {
                Task {
                    vm.isBusy = true
                    defer { vm.isBusy = false }

                    guard vm.password == confirmPassword else { return }

                    await session.signUp(email: vm.email, password: vm.password)
                    session.setBiometricsEnabled(vm.wantsBiometrics)

                    // ensure we only proceed if no error
                    if session.errorMessage == nil {
                        session.signOut()  // not auto-logged in
                        vm.clear()
                        dismiss()          // ← pop back to LoginView
                    }
                }
            } label: {
                Text(vm.isBusy ? "Creating…" : "Sign Up").frame(maxWidth: .infinity) // Same button text style as LoginView
            }
            .buttonStyle(.borderedProminent) // Same button style as LoginView
            .disabled(!isFormValid || vm.isBusy)

            if let err = session.errorMessage {
                Text(err).foregroundStyle(.red).font(.footnote).multilineTextAlignment(.center) // Same error style as LoginView
            }

            Spacer()
        }
        .padding() // Same padding as LoginView
    }

    private var isFormValid: Bool {
        vm.email.contains("@") && vm.password.count >= 6 && vm.password == confirmPassword && agreedPolicy
    }
}

#Preview("SignupView") {
    SignupView()
        .environmentObject(SessionStore())
}
