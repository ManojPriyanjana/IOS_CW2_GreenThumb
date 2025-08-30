import SwiftUI

struct PasswordChangedSuccessView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.seal.fill").font(.system(size: 48))
            Text("Password Changed!").font(.title2).bold()
            Text("Your password has been reset successfully.")
                .font(.footnote).foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Continue") { dismiss() }          // go back to Login
                .frame(maxWidth: .infinity)
                .buttonStyle(.borderedProminent)

            Spacer()
        }
        .padding()
    }
}
