import Foundation
import LocalAuthentication

enum BiometricKind { case none, touchID, faceID }

enum BiometricAuth {
    static func kind() -> BiometricKind {
        let ctx = LAContext()
        var error: NSError?
        let ok = ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        guard ok else { return .none }
        switch ctx.biometryType {
        case .touchID: return .touchID
        case .faceID:  return .faceID
        default:       return .none
        }
    }

    static func evaluate(reason: String) async throws -> LAContext {
        try await withCheckedThrowingContinuation { cont in
            let ctx = LAContext()
            ctx.localizedFallbackTitle = "Use Password"
            ctx.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, error in
                if success { cont.resume(returning: ctx) }
                else { cont.resume(throwing: error ?? NSError(domain: "Biometrics", code: -1)) }
            }
        }
    }
}
