import SwiftUI

struct SecuritySettingsView: View {
    @EnvironmentObject var session: SessionStore

    var body: some View {
        Form {
            Section("Security") {
                Toggle("Use Face ID / Touch ID", isOn: Binding(
                    get: { session.biometricsEnabled },
                    set: { session.setBiometricsEnabled($0) }
                ))
                Text(session.biometricsEnabled
                     ? "Quickly unlock your account with biometrics."
                     : "You’ll use your password on next launch.")
                .font(.footnote).foregroundStyle(.secondary)
            }

            Section {
                Button(role: .destructive) { session.signOut() } label: { Text("Sign Out") }
            }
        }
        .navigationTitle("Settings")
    }
}
