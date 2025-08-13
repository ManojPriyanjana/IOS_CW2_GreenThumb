import SwiftUI

struct LockView: View {
    @EnvironmentObject var session: SessionStore

    private var title: String {
        switch BiometricAuth.kind() {
        case .faceID: return "Unlock with Face ID"
        case .touchID: return "Unlock with Touch ID"
        case .none: return "Unlock"
        }
    }

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.fill").font(.system(size: 40))
            Text("Welcome back").font(.title2).bold()

            Button(title) {
                Task { await session.unlockWithBiometrics() }
            }
            .buttonStyle(.borderedProminent)

            Button("Use password instead") {
                session.setBiometricsEnabled(false) // optional: disable for this run
                session.signOut() // go back to Login
            }
            .padding(.top, 8)

            if let err = session.errorMessage {
                Text(err).foregroundStyle(.red).font(.footnote).multilineTextAlignment(.center)
            }
        }
        .padding()
    }
}
