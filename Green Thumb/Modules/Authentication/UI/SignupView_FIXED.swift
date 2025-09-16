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
    @EnvironmentObject private var colorCtl: ColorSchemeController

    @Environment(\.dismiss) private var dismiss
    
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var agreedPolicy = false

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Modern Header with Icon
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [Color.green.opacity(0.2), Color.mint.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 80, height: 80)
                        Image(systemName: "leaf.fill")
                            .font(.largeTitle)
                            .fontWeight(.semibold)
                            .foregroundStyle(.green)
                    }
                    
                    VStack(spacing: 4) {
                        Text("Create Account")
                            .font(.title)
                            .foregroundColor(.primary)
                        Text("Join Green Thumb community")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.top, 32)

                // Modern Form Fields
                VStack(spacing: 20) {
                    modernTextField(icon: "envelope.fill", placeholder: "Email Address", text: $vm.email)
                    modernSecureField(icon: "lock.fill", placeholder: "Password", text: $vm.password, isVisible: $showPassword)
                    modernSecureField(icon: "lock.rotation", placeholder: "Confirm Password", text: $confirmPassword, isVisible: $showConfirmPassword)
                }

                // Modern Privacy Toggle
                HStack(spacing: 16) {
                    Button {
                        agreedPolicy.toggle()
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(agreedPolicy ? Color.green : Color(.systemGray4))
                                .frame(width: 24, height: 24)
                            if agreedPolicy {
                                Image(systemName: "checkmark")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    
                    Text("I agree with privacy policy and terms")
                        .font(.callout)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }

                // Modern Sign Up Button
                Button {
                    Task {
                        vm.isBusy = true
                        defer { vm.isBusy = false }

                        guard vm.password == confirmPassword else { return }

                        await session.signUp(email: vm.email, password: vm.password)

                        if session.errorMessage == nil {
                            session.signOut()
                            vm.clear()
                            dismiss()
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        if vm.isBusy {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(.white)
                        }
                        Text(vm.isBusy ? "Creating Account..." : "Create Account")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isFormValid ? Color.green : Color(.systemGray4))
                    )
                    .foregroundColor(.white)
                }
                .disabled(!isFormValid || vm.isBusy)

                // Modern Divider
                HStack(spacing: 16) {
                    Rectangle()
                        .frame(height: 1)
                        .foregroundStyle(Color(.systemGray3))
                    Text("or continue with")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    Rectangle()
                        .frame(height: 1)
                        .foregroundStyle(Color(.systemGray3))
                }

                // Modern Social Buttons
                HStack(spacing: 16) {
                    modernSocialButton("google", color: .red)
                    modernSocialButton("applelogo", color: .black)
                    modernSocialButton("facebook", color: .blue)
                }

                // Bottom Navigation
                HStack(spacing: 4) {
                    Text("Already have an account?")
                        .font(.callout)
                        .foregroundColor(.secondary)
                    NavigationLink("Sign In") {
                        LoginView()
                    }
                    .font(.callout)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
                }

                if let err = session.errorMessage {
                    Text(err)
                        .foregroundStyle(.red)
                        .font(.callout)
                        .multilineTextAlignment(.center)
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemBackground))
                                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                        )
                        .padding(.horizontal, 8)
                }
            }
            .padding(32)
        }
        .background(
            LinearGradient(colors: [Color.green.opacity(0.02), Color.mint.opacity(0.01)], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
        )
    }

    private var isFormValid: Bool {
        vm.email.contains("@") && vm.password.count >= 6 && vm.password == confirmPassword && agreedPolicy
    }

    @ViewBuilder
    private func modernTextField(icon: String, placeholder: String, text: Binding<String>) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.green)
                .frame(width: 24)
            
            TextField(placeholder, text: text)
                .font(.body)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.separator), lineWidth: 0.5)
        )
    }

    @ViewBuilder
    private func modernSecureField(icon: String, placeholder: String, text: Binding<String>, isVisible: Binding<Bool>) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.green)
                .frame(width: 24)
            
            if isVisible.wrappedValue {
                TextField(placeholder, text: text)
                    .font(.body)
            } else {
                SecureField(placeholder, text: text)
                    .font(.body)
            }
            
            Button {
                isVisible.wrappedValue.toggle()
            } label: {
                Image(systemName: isVisible.wrappedValue ? "eye.slash.fill" : "eye.fill")
                    .font(.title3)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.separator), lineWidth: 0.5)
        )
    }
    
    @ViewBuilder
    private func modernSocialButton(_ icon: String, color: Color) -> some View {
        Button {
            // Social login action
        } label: {
            Image(systemName: icon)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(color)
                .frame(width: 56, height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemBackground))
                        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                )
        }
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
