// Modules/Authentication/Views/LoginView.swift
import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel = AuthViewModel()
    @State private var showSignup = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {

                    Image(systemName: "leaf.fill") // replace with your asset if you have one
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .padding(.top, 24)

                    Text("GreenThumb")
                        .font(.system(size: 34, weight: .bold))
                    Text("Login")
                        .font(.title2)

                    VStack(spacing: 12) {
                        TextField("Email", text: $viewModel.email)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 12).stroke(.gray.opacity(0.35)))

                        SecureField("Password", text: $viewModel.password)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 12).stroke(.gray.opacity(0.35)))
                    }
                    .padding(.top, 8)

                    Toggle(isOn: $viewModel.rememberMe) {
                        Text("Remember me")
                    }
                    .toggleStyle(CheckboxToggleStyle())   
                    .padding(.top, 4)

                    Button {
                        viewModel.login()
                    } label: {
                        Text("Sign in")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .font(.headline)
                    }
                    .buttonStyle(.borderedProminent)
                    .clipShape(RoundedRectangle(cornerRadius: 18))

                    Button {
                        viewModel.useFaceID()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "faceid")
                            Text("Use Face ID")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.bordered)

                    Button("forgot the password") {
                        // TODO: implement reset flow
                    }
                    .font(.subheadline)
                    .padding(.top, 4)

                    HStack {
                        Rectangle().frame(height: 1).opacity(0.2)
                        Text("or continue with")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Rectangle().frame(height: 1).opacity(0.2)
                    }
                    .padding(.vertical, 8)

                    HStack(spacing: 28) {
                        Image(systemName: "person.2.circle").font(.title2)  // FB placeholder
                        Image(systemName: "globe").font(.title2)             // Google placeholder
                        Image(systemName: "apple.logo").font(.title2)        // Apple
                    }
                    .padding(.bottom, 6)

                    HStack(spacing: 6) {
                        Text("Already have an account?")
                        Button("Sign Up") { showSignup = true }
                            .fontWeight(.semibold)
                    }
                    .padding(.bottom, 24)

                    if !viewModel.errorMessage.isEmpty {
                        Text(viewModel.errorMessage)
                            .foregroundColor(.red)
                            .font(.footnote)
                    }
                }
                .padding(.horizontal, 20)
            }
            .navigationTitle("Login Page")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showSignup) { SignupView() }
        .fullScreenCover(isPresented: $viewModel.isAuthenticated) { DashboardView() }
    }
}
