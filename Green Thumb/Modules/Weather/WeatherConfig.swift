import Foundation

/// Central place to keep configuration for Weather features.
/// TODO: Move the API key to a secure location (e.g., Info.plist with environment configs)
enum WeatherConfig {
    /// OpenWeather API key used across the app. Keep in sync with your project settings.
    static let apiKey: String = "15845b53595b293a72d288d11d16cb39"
}
