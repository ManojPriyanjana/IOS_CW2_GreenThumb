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

private extension Color {
    static let primaryGreen  = Color(red: 0.08,  green: 0.47,  blue: 0.33) // #157954
    static let mintAccent    = Color(red: 0.34,  green: 0.77,  blue: 0.59) // #56C596
    static let softMintBG    = Color(red: 0.81,  green: 0.96,  blue: 0.82) // #CFF4D2
    static let darkBase      = Color(red: 0.13,  green: 0.15,  blue: 0.23) // #21263A
    static let textPrimary   = Color(red: 0.11,  green: 0.14,  blue: 0.13) // #1B2320
    static let textSecondary = Color(red: 0.25,  green: 0.32,  blue: 0.29) // #3F514B
    static let dividers      = Color(red: 0.90,  green: 0.94,  blue: 0.91) // #E5EFE9
}

struct SignupView: View {
    @EnvironmentObject var session: SessionStore
    @StateObject private var vm = AuthViewModel()

    @Environment(\.dismiss) private var dismiss
    
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var agreedPolicy = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Create Account")
                        .font(.title2.bold())
                        .foregroundStyle(Color.primaryGreen)
                    Text("Sign up to continue")
                        .font(.footnote)
                        .foregroundStyle(Color.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Email field
                customField(icon: "envelope", placeholder: "Email Address", text: $vm.email)

                // Password field
                customSecureField(icon: "lock", placeholder: "Password", text: $vm.password, isVisible: $showPassword)

                // Confirm password field
                customSecureField(icon: "lock.rotation", placeholder: "Confirm Password", text: $confirmPassword, isVisible: $showConfirmPassword)

                // Privacy policy checkbox
                Toggle(isOn: $agreedPolicy) {
                    Text("I agree with privacy policy")
                        .font(.footnote)
                }
                .toggleStyle(.checkbox)
                .tint(.primaryGreen)

                // Sign Up button
                Button {
                    Task {
                        vm.isBusy = true
                        defer { vm.isBusy = false }

                        guard vm.password == confirmPassword else { return }

                        await session.signUp(email: vm.email, password: vm.password)

                        // ensure we only proceed if no error
                        if session.errorMessage == nil {
                            session.signOut()  // not auto-logged in
                            vm.clear()
                            dismiss()          // ← pop back to LoginView
                        }
                    }
                } label: {
                    Text(vm.isBusy ? "Creating..." : "Sign Up")
                        .frame(maxWidth: .infinity).padding()
                }
                .disabled(!isFormValid || vm.isBusy)


                // OR divider
                HStack {
                    Rectangle().frame(height: 1).foregroundStyle(Color.dividers)
                    Text("or sign up with").font(.caption).foregroundStyle(.secondary)
                    Rectangle().frame(height: 1).foregroundStyle(Color.dividers)
                }

                // Social logins
                HStack(spacing: 20) {
                    socialButton("google")
                    socialButton("applelogo")
                    socialButton("facebook")
                }

                // Bottom link
                HStack {
                    Text("Already have an account?")
                        .font(.footnote)
                    NavigationLink("Login") {
                        LoginView()
                    }
                    .font(.footnote.bold())
                    .foregroundColor(.primaryGreen)
                }
                .padding(.top, 12)

                if let err = session.errorMessage {
                    Text(err).foregroundStyle(.red).font(.footnote)
                }
            }
            .padding(20)
        }
        .background(Color.softMintBG.opacity(0.25).ignoresSafeArea())
    }

    private var isFormValid: Bool {
        vm.email.contains("@") && vm.password.count >= 6 && vm.password == confirmPassword && agreedPolicy
    }

    @ViewBuilder
    private func customField(icon: String, placeholder: String, text: Binding<String>) -> some View {
        HStack {
            Image(systemName: icon).foregroundStyle(.secondary)
            TextField(placeholder, text: text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        }
        .padding()
        .background(Color.white)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.dividers))
    }

    @ViewBuilder
    private func customSecureField(icon: String, placeholder: String, text: Binding<String>, isVisible: Binding<Bool>) -> some View {
        HStack {
            Image(systemName: icon).foregroundStyle(.secondary)
            if isVisible.wrappedValue {
                TextField(placeholder, text: text)
            } else {
                SecureField(placeholder, text: text)
            }
            Button {
                isVisible.wrappedValue.toggle()
            } label: {
                Image(systemName: isVisible.wrappedValue ? "eye.slash" : "eye")
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color.white)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.dividers))
    }

    private func socialButton(_ systemName: String) -> some View {
        Button { /* hook your social login here */ } label: {
            Image(systemName: systemName)
                .font(.title3)
                .frame(width: 44, height: 44)
                .background(Color.dividers)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }
}

// Simple checkmark toggle style
struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                .foregroundColor(configuration.isOn ? .primaryGreen : .secondary)
                .onTapGesture { configuration.isOn.toggle() }
            configuration.label
        }
    }
}

extension ToggleStyle where Self == CheckboxToggleStyle {
    static var checkbox: CheckboxToggleStyle { .init() }
}

