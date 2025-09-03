import Foundation
import Combine
import FirebaseAuth
import LocalAuthentication

@MainActor
final class SessionStore: ObservableObject {
    enum Phase { case loading, loggedOut, locked, authenticated }
    @Published private(set) var phase: Phase = .loading
    @Published var errorMessage: String?

    private let auth = AuthService()
    private let biometricsEnabledKey = "gt.biometrics.enabled"

    var biometricsEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: biometricsEnabledKey) }
        set { UserDefaults.standard.set(newValue, forKey: biometricsEnabledKey) }
    }

    init() {
        Task { await bootstrap() }
    }

    //Lifecycle

    func bootstrap() async {
        if auth.currentUser() != nil {
            if biometricsEnabled, KeychainService.hasProtectedSession() {
                phase = .locked
            } else {
                phase = .authenticated
            }
        } else {
            phase = .loggedOut
        }
    }

    //  Auth

    func signUp(email: String, password: String) async {
        await withErrorHandling {
            _ = try await auth.signUp(email: email, password: password)
            try await postSignIn()
        }
    }

    func signIn(email: String, password: String) async {
        await withErrorHandling {
            _ = try await auth.signIn(email: email, password: password)
            try await postSignIn()
        }
    }

    func signOut() {
        do {
            try auth.signOut()
            _ = try? KeychainService.deleteBiometricProtected()
            phase = .loggedOut
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // Biometrics / Keychain

    func setBiometricsEnabled(_ enabled: Bool) {
        biometricsEnabled = enabled
        if enabled, let uid = auth.currentUser()?.uid {
            try? KeychainService.saveBiometricProtected(Data(uid.utf8))
        } else {
            _ = try? KeychainService.deleteBiometricProtected()
        }
    }

    func unlockWithBiometrics() async {
        await withErrorHandling {
            let ctx = try await BiometricAuth.evaluate(reason: "Unlock your session")
            _ = try KeychainService.readBiometricProtected(context: ctx) // verify item
            phase = .authenticated
        }
    }

    // Helpers

    private func postSignIn() async throws {
        if biometricsEnabled, let uid = auth.currentUser()?.uid {
            try KeychainService.saveBiometricProtected(Data(uid.utf8))
        }
        phase = biometricsEnabled ? .locked : .authenticated
    }

    /// Fix: accept async throwing work and await it here
    private func withErrorHandling(_ work: () async throws -> Void) async {
        errorMessage = nil
        do { try await work() }
        catch { errorMessage = error.localizedDescription }
    }
}
