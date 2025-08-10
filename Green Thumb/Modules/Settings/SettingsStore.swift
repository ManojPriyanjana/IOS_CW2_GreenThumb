import Foundation
protocol SettingsStore {
    func load() -> AppSettings
    func save(_ settings: AppSettings)
}
