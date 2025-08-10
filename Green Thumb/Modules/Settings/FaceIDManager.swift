import LocalAuthentication

final class FaceIDManager {
    static let shared = FaceIDManager(); private init() {}

    func canUseBiometrics() -> Bool {
        var err: NSError?
        let ctx = LAContext()
        return ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &err)
    }

    func authenticate(reason: String = "Authenticate to enable Face ID",
                      completion: @escaping (Bool) -> Void) {
        let ctx = LAContext()
        var err: NSError?
        if ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &err) {
            ctx.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) {
                ok, _ in DispatchQueue.main.async { completion(ok) }
            }
        } else {
            DispatchQueue.main.async { completion(false) } // Simulator: returns false
        }
    }
}
