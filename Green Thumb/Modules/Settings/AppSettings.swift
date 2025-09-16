import Foundation

struct AppSettings: Equatable {
    var faceID: Bool
    var pushNotifications: Bool
    var taskReminders: Bool
    var diseaseAlerts: Bool
    // EventKit integration flags
    var syncTasksToReminders: Bool
    var syncHarvestToCalendar: Bool
    var syncTasksToCalendar: Bool
    var syncHealthToCalendar: Bool
    var quietStart: Int   // seconds since midnight
    var quietEnd: Int
    var highContrast: Bool
    var reduceMotion: Bool
    var darkModeEnabled: Bool

    static let `default` = AppSettings(
        faceID: true, pushNotifications: true, taskReminders: true, diseaseAlerts: true,
    syncTasksToReminders: false, syncHarvestToCalendar: false,
    syncTasksToCalendar: false, syncHealthToCalendar: false,
        quietStart: 21*3600, quietEnd: 7*3600, highContrast: false, reduceMotion: false,
        darkModeEnabled: false
    )
}

