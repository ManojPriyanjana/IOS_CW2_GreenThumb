import Foundation

struct AppSettings: Equatable {
    var faceID: Bool
    var pushNotifications: Bool
    var taskReminders: Bool
    var diseaseAlerts: Bool
    var quietStart: Int   // seconds since midnight
    var quietEnd: Int
    var highContrast: Bool
    var reduceMotion: Bool

    static let `default` = AppSettings(
        faceID: true, pushNotifications: true, taskReminders: true, diseaseAlerts: true,
        quietStart: 21*3600, quietEnd: 7*3600, highContrast: false, reduceMotion: false
    )
}

