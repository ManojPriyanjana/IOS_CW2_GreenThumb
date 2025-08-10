import Foundation

final class SettingsViewModel: ObservableObject {
    @Published var settings: AppSettings
    private let store: SettingsStore

    init(store: SettingsStore = UserDefaultsSettingsStore()) {
        self.store = store
        self.settings = store.load()
    }

    func toggleFaceID(_ enabled: Bool, completion: @escaping (Bool) -> Void) {
        if enabled {
            FaceIDManager.shared.authenticate { [weak self] ok in
                guard let self = self else { return }
                self.settings.faceID = ok
                self.persist(); completion(ok)
            }
        } else { settings.faceID = false; persist(); completion(true) }
    }

    func setPushNotifications(_ enabled: Bool) {
        if enabled {
            NotificationManager.shared.requestAuth { [weak self] granted in
                guard let self = self else { return }
                self.settings.pushNotifications = granted
                self.persist()
            }
        } else { settings.pushNotifications = false; persist() }
    }

    func setTaskReminders(_ v: Bool) { settings.taskReminders = v; persist() }
    func setDiseaseAlerts(_ v: Bool) { settings.diseaseAlerts = v; persist() }

    func updateQuietHours(start: Int, end: Int) {
        settings.quietStart = start; settings.quietEnd = end; persist()
    }

    func setHighContrast(_ v: Bool) { settings.highContrast = v; persist() }
    func setReduceMotion(_ v: Bool) { settings.reduceMotion = v; persist() }

    private func persist() { store.save(settings) }
}
