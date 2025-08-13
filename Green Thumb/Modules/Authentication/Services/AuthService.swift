import Foundation
import FirebaseAuth

struct AuthService {
    func signUp(email: String, password: String) async throws -> User {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        return result.user
    }

    func signIn(email: String, password: String) async throws -> User {
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        return result.user
    }

    func signOut() throws {
        try Auth.auth().signOut()
    }

    func currentUser() -> User? {
        Auth.auth().currentUser
    }

    /// Grab a fresh ID token if you ever need it for APIs.
    func idToken(forceRefresh: Bool = false) async throws -> String {
        try await withCheckedThrowingContinuation { cont in
            Auth.auth().currentUser?.getIDTokenForcingRefresh(forceRefresh) { token, err in
                if let err { cont.resume(throwing: err) }
                else { cont.resume(returning: token ?? "") }
            }
        }
    }
}
