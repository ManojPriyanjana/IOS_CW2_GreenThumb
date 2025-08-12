import Foundation

public final class OpenWeatherClient: WeatherServicing {
    private let apiKey: String
    private let session: URLSession

    public init(apiKey: String, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
    }

    public func currentWeather(lat: Double, lon: Double) async throws -> Weather {
        var comps = URLComponents(string: "https://api.openweathermap.org/data/2.5/weather")!
        comps.queryItems = [
            .init(name: "lat", value: String(lat)),
            .init(name: "lon", value: String(lon)),
            .init(name: "appid", value: apiKey)
        ]
        let (data, resp) = try await session.data(from: comps.url!)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        let raw = try JSONDecoder().decode(OWCurrentResponse.self, from: data)
        return Weather.from(raw)
    }
}

// Mock for previews/tests
public struct MockWeatherService: WeatherServicing {
    public init() {}
    public func currentWeather(lat: Double, lon: Double) async throws -> Weather {
        Weather(
            city: "Colombo", country: "LK",
            temperatureK: 302.15, description: "Clear Sky", icon: "01d",
            windSpeed: 3.6, humidity: 62, dt: Date()
        )
    }
}
