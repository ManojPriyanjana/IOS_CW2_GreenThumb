//import SwiftUI
//
//struct SettingsView: View {
//    @StateObject private var vm = SettingsViewModel()
//    @State private var faceIDAlert = false
//
//    var body: some View {
//        NavigationStack {
//            List {
//                Section("General") {
//                    Toggle("Face ID", isOn: Binding(
//                        get: { vm.settings.faceID },
//                        set: { newVal in
//                            vm.toggleFaceID(newVal) { ok in if !ok { faceIDAlert = true } }
//                        })
//                    )
//                    NavigationLink("Change Password") {
//                        Text("Change Password (stub)")
//                            .font(.callout).foregroundStyle(.secondary)
//                    }
//                }
//
//                Section("Notifications") {
//                    Toggle("Push Notifications",
//                           isOn: Binding(get: { vm.settings.pushNotifications },
//                                         set: { vm.setPushNotifications($0) }))
//                    Toggle("Task Reminders",
//                           isOn: Binding(get: { vm.settings.taskReminders },
//                                         set: { vm.setTaskReminders($0) }))
//                    Toggle("Disease Alerts",
//                           isOn: Binding(get: { vm.settings.diseaseAlerts },
//                                         set: { vm.setDiseaseAlerts($0) }))
//
//                    NavigationLink {
//                        QuietHoursView(start: vm.settings.quietStart,
//                                       end: vm.settings.quietEnd) { s, e in
//                            vm.updateQuietHours(start: s, end: e)
//                        }
//                    } label: {
//                        HStack {
//                            Text("Quiet Hours")
//                            Spacer()
//                            Text("\(format(vm.settings.quietStart)) - \(format(vm.settings.quietEnd))")
//                                .foregroundStyle(.secondary)
//                        }
//                    }
//                }
//
//                Section("Data and backup") {
//                    NavigationLink("Manage Storage") { ManageStorageView() }
//                }
//
//                Section("Accessibility") {
//                    NavigationLink("Larger Text") {
//                        Text("We respect Dynamic Type.\nAdjust in iOS Settings → Accessibility → Display & Text Size.")
//                            .padding()
//                    }
//                    Toggle("High Contrast Mode",
//                           isOn: Binding(get: { vm.settings.highContrast },
//                                         set: { vm.setHighContrast($0) }))
//                    Toggle("Reduce Motion",
//                           isOn: Binding(get: { vm.settings.reduceMotion },
//                                         set: { vm.setReduceMotion($0) }))
//                    NavigationLink("Voice Over") {
//                        Text("VoiceOver is managed by iOS. We provide labels & hints throughout the app.")
//                            .padding()
//                    }
//                }
//                
//            }
//            .navigationTitle("Settings")
//            .alert("Face ID unavailable on this device/simulator.", isPresented: $faceIDAlert) {
//                Button("OK", role: .cancel) {}
//            }
//        }
//    }
//
//    private func format(_ secs: Int) -> String {
//        String(format: "%02d:%02d", secs/3600, (secs%3600)/60)
//    }
//}
//



import SwiftUI
import LocalAuthentication

struct SettingsView: View {
    // NEW: talk to your auth/session layer directly
    @EnvironmentObject var session: SessionStore

    @StateObject private var vm = SettingsViewModel()
    @State private var faceIDAlert = false
    @State private var biometryMessage = ""

    // Show proper label depending on device capability
    private var biometryLabel: String {
        switch BiometricAuth.kind() {
        case .faceID:  return "Face ID"
        case .touchID: return "Touch ID"
        case .none:    return "Biometrics"
        }
    }

    var body: some View {
        NavigationStack {
            List {
                // MARK: - General
                Section("General") {
                    // Face ID / Touch ID toggle now bound to SessionStore
                    Toggle(biometryLabel, isOn: Binding(
                        get: { session.biometricsEnabled },
                        set: { newVal in
                            if newVal {
                                // Check device/simulator status before enabling
                                let (available, message) = canUseBiometrics()
                                if available {
                                    session.setBiometricsEnabled(true)
                                } else {
                                    biometryMessage = message
                                    faceIDAlert = true
                                    session.setBiometricsEnabled(false)
                                }
                            } else {
                                session.setBiometricsEnabled(false)
                            }
                        })
                    )

                    NavigationLink("Change Password") {
                        Text("Change Password (stub)")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                }

                // MARK: - Notifications
                Section("Notifications") {
                    Toggle("Push Notifications",
                           isOn: Binding(get: { vm.settings.pushNotifications },
                                         set: { vm.setPushNotifications($0) }))
                    Toggle("Task Reminders",
                           isOn: Binding(get: { vm.settings.taskReminders },
                                         set: { vm.setTaskReminders($0) }))
                    Toggle("Disease Alerts",
                           isOn: Binding(get: { vm.settings.diseaseAlerts },
                                         set: { vm.setDiseaseAlerts($0) }))

                    NavigationLink {
                        QuietHoursView(start: vm.settings.quietStart,
                                       end: vm.settings.quietEnd) { s, e in
                            vm.updateQuietHours(start: s, end: e)
                        }
                    } label: {
                        HStack {
                            Text("Quiet Hours")
                            Spacer()
                            Text("\(format(vm.settings.quietStart)) - \(format(vm.settings.quietEnd))")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // MARK: - Data & backup
                Section("Data and backup") {
                    NavigationLink("Manage Storage") { ManageStorageView() }
                }

                // MARK: - Accessibility
                Section("Accessibility") {
                    NavigationLink("Larger Text") {
                        Text("We respect Dynamic Type.\nAdjust in iOS Settings → Accessibility → Display & Text Size.")
                            .padding()
                    }
                    Toggle("High Contrast Mode",
                           isOn: Binding(get: { vm.settings.highContrast },
                                         set: { vm.setHighContrast($0) }))
                    Toggle("Reduce Motion",
                           isOn: Binding(get: { vm.settings.reduceMotion },
                                         set: { vm.setReduceMotion($0) }))
                    NavigationLink("Voice Over") {
                        Text("VoiceOver is managed by iOS. We provide labels & hints throughout the app.")
                            .padding()
                    }
                }
            }
            .navigationTitle("Settings")
            .alert(biometryLabel + " unavailable", isPresented: $faceIDAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(biometryMessage)
            }
        }
    }

    // MARK: - Helpers

    private func format(_ secs: Int) -> String {
        String(format: "%02d:%02d", secs/3600, (secs%3600)/60)
    }

    /// Returns (available, message). If not available, message explains what to do.
    private func canUseBiometrics() -> (Bool, String) {
        let ctx = LAContext()
        var error: NSError?
        let ok = ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)

        if ok { return (true, "") }

        if let laError = error as? LAError {
            switch laError.code {
            case .biometryNotEnrolled:
                return (false, "Biometry is not enrolled.\nSimulator: Features → \(biometryLabel) → Enrolled.")
            case .biometryNotAvailable:
                return (false, "\(biometryLabel) is not available on this device.")
            case .biometryLockout:
                return (false, "Too many attempts. Use password or try again later.")
            default:
                return (false, laError.localizedDescription)
            }
        }
        return (false, "Unable to use \(biometryLabel) on this device.")
    }
}
