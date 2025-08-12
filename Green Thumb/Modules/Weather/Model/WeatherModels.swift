import Foundation

public struct Weather: Equatable {
    public let city: String
    public let country: String?
    public let temperatureK: Double
    public let description: String
    public let icon: String?
    public let windSpeed: Double?
    public let humidity: Int?
    public let dt: Date

    public var temperatureC: Double { temperatureK - 273.15 }
    public var temperatureF: Double { (temperatureK - 273.15) * 9/5 + 32 }
}

// Only the fields we use from OpenWeather "Current Weather Data"
struct OWCurrentResponse: Decodable {
    struct Sys: Decodable { let country: String? }
    struct Main: Decodable { let temp: Double; let humidity: Int? }
    struct Wind: Decodable { let speed: Double? }
    struct W: Decodable { let description: String; let icon: String? }
    let name: String
    let sys: Sys
    let main: Main
    let weather: [W]
    let wind: Wind?
    let dt: TimeInterval
}

extension Weather {
    static func from(_ r: OWCurrentResponse) -> Weather {
        Weather(
            city: r.name,
            country: r.sys.country,
            temperatureK: r.main.temp,
            description: r.weather.first?.description.capitalized ?? "—",
            icon: r.weather.first?.icon,
            windSpeed: r.wind?.speed,
            humidity: r.main.humidity,
            dt: Date(timeIntervalSince1970: r.dt)
        )
    }
}
