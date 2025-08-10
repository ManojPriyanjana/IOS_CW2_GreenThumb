import Foundation

final class UserDefaultsSettingsStore: SettingsStore {
    private let ud = UserDefaults.standard

    func load() -> AppSettings {
        AppSettings(
            faceID: ud.object(forKey: SettingsKeys.faceID.rawValue) as? Bool ?? AppSettings.default.faceID,
            pushNotifications: ud.object(forKey: SettingsKeys.pushNotifications.rawValue) as? Bool ?? AppSettings.default.pushNotifications,
            taskReminders: ud.object(forKey: SettingsKeys.taskReminders.rawValue) as? Bool ?? AppSettings.default.taskReminders,
            diseaseAlerts: ud.object(forKey: SettingsKeys.diseaseAlerts.rawValue) as? Bool ?? AppSettings.default.diseaseAlerts,
            quietStart: ud.object(forKey: SettingsKeys.quietStart.rawValue) as? Int ?? AppSettings.default.quietStart,
            quietEnd: ud.object(forKey: SettingsKeys.quietEnd.rawValue) as? Int ?? AppSettings.default.quietEnd,
            highContrast: ud.object(forKey: SettingsKeys.highContrast.rawValue) as? Bool ?? AppSettings.default.highContrast,
            reduceMotion: ud.object(forKey: SettingsKeys.reduceMotion.rawValue) as? Bool ?? AppSettings.default.reduceMotion
        )
    }

    func save(_ s: AppSettings) {
        ud.set(s.faceID,            forKey: SettingsKeys.faceID.rawValue)
        ud.set(s.pushNotifications, forKey: SettingsKeys.pushNotifications.rawValue)
        ud.set(s.taskReminders,     forKey: SettingsKeys.taskReminders.rawValue)
        ud.set(s.diseaseAlerts,     forKey: SettingsKeys.diseaseAlerts.rawValue)
        ud.set(s.quietStart,        forKey: SettingsKeys.quietStart.rawValue)
        ud.set(s.quietEnd,          forKey: SettingsKeys.quietEnd.rawValue)
        ud.set(s.highContrast,      forKey: SettingsKeys.highContrast.rawValue)
        ud.set(s.reduceMotion,      forKey: SettingsKeys.reduceMotion.rawValue)
    }
}
