import Foundation

public protocol WeatherServicing {
    func currentWeather(lat: Double, lon: Double) async throws -> Weather
}
