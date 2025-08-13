// Modules/Authentication/ViewModels/AuthViewModel.swift
import Foundation
import LocalAuthentication

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var rememberMe: Bool = false

    @Published var isAuthenticated: Bool = false
    @Published var errorMessage: String = ""

    func login() {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter email and password."
            return
        }
        errorMessage = ""
        if rememberMe { UserDefaults.standard.set(true, forKey: "useBiometrics") }
        // TODO: replace with real auth
        isAuthenticated = true
    }

    func useFaceID() {
        let ctx = LAContext()
        var err: NSError?
        guard ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &err) else {
            errorMessage = err?.localizedDescription ?? "Face ID not available."
            return
        }
        Task {
            do {
                let ok = try await ctx.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                                                      localizedReason: "Sign in with Face ID")
                if ok {
                    errorMessage = ""
                    isAuthenticated = true  // restore session/token in a real app
                } else {
                    errorMessage = "Face ID was not successful."
                }
            } catch {
                errorMessage = "Face ID failed: \(error.localizedDescription)"
            }
        }
    }
}
