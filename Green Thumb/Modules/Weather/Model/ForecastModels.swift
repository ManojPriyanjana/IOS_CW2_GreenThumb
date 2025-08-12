import Foundation

public struct ForecastDay: Identifiable, Equatable {
    public let id = UUID()
    public let date: Date
    public let minC: Double
    public let maxC: Double
    public let rainChance: Int   // %
    public let summary: String
}

// Raw OpenWeather 5-day / 3-hour forecast response
// https://api.openweathermap.org/data/2.5/forecast
struct OWForecastResponse: Decodable {
    struct Item: Decodable {
        struct Main: Decodable { let temp_min: Double; let temp_max: Double }
        struct W: Decodable { let description: String }
        let dt: TimeInterval
        let main: Main
        let weather: [W]
        let pop: Double? // probability of precipitation 0...1
    }
    let list: [Item]
}
