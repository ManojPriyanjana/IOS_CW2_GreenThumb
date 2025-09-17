import SwiftUI

struct PasswordChangedSuccessView: View {
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "checkmark.seal.fill").font(.largeTitle)
            Text("Password Changed!").font(.title2).bold()
            Text("Your password has been reset successfully.")
                .font(.footnote).foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Continue") {
                // Pop all the way back to root (Login)
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first,
                   let navController = window.rootViewController?.presentedViewController as? UINavigationController ?? 
                                      window.rootViewController as? UINavigationController {
                    navController.popToRootViewController(animated: true)
                } else {
                    // Fallback: dismiss this modal and all beneath it
                    presentationMode.wrappedValue.dismiss()
                }
            }
                .frame(maxWidth: .infinity)
                .buttonStyle(.borderedProminent)

            Spacer()
        }
        .padding()
    }
}

#Preview("PasswordChangedSuccessView") {
    NavigationStack {
        PasswordChangedSuccessView()
            .environmentObject(SessionStore())          // only if needed
            .environmentObject(ColorSchemeController())  // only if used
     }
}

