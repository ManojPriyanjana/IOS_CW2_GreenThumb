import SwiftUI

struct SettingsView: View {
    @StateObject private var vm = SettingsViewModel()
    @State private var faceIDAlert = false

    var body: some View {
        NavigationStack {
            List {
                Section("General") {
                    Toggle("Face ID", isOn: Binding(
                        get: { vm.settings.faceID },
                        set: { newVal in
                            vm.toggleFaceID(newVal) { ok in if !ok { faceIDAlert = true } }
                        })
                    )
                    NavigationLink("Change Password") {
                        Text("Change Password (stub)")
                            .font(.callout).foregroundStyle(.secondary)
                    }
                }

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

                Section("Data and backup") {
                    NavigationLink("Manage Storage") { ManageStorageView() }
                }

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
            .alert("Face ID unavailable on this device/simulator.", isPresented: $faceIDAlert) {
                Button("OK", role: .cancel) {}
            }
        }
    }

    private func format(_ secs: Int) -> String {
        String(format: "%02d:%02d", secs/3600, (secs%3600)/60)
    }
}

