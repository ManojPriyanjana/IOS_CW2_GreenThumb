import Foundation
import Firebase
import FirebaseAuth
import LocalAuthentication

class AuthViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var isAuthenticated = false
    @Published var errorMessage = ""

    // MARK: - Login
    func login() {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                } else {
                    self?.isAuthenticated = true
                }
            }
        }
    }

    // MARK: - Signup
    func signup(completion: @escaping () -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                } else {
                    completion()
                }
            }
        }
    }

    // MARK: - Face ID Login
    func useFaceID() {
        print("🟡 Attempting Face ID")
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            print("Face ID Available - Prompt showing...")
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                                   localizedReason: "Login with Face ID") { success, error in
                DispatchQueue.main.async {
                    if success {
                        print("Face ID Success")
                        self.isAuthenticated = true
                    } else {
                        print("Face ID Failed: \(error?.localizedDescription ?? "Unknown error")")
                        self.errorMessage = error?.localizedDescription ?? "Face ID failed"
                    }
                }
            }
        } else {
            print("Face ID NOT available: \(error?.localizedDescription ?? "Unknown reason")")
            errorMessage = "Face ID not available"
        }
    }
}
