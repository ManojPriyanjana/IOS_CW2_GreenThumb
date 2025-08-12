import Foundation

public final class OpenWeatherForecastClient: ForecastServicing {
    private let apiKey: String
    private let session: URLSession

    public init(apiKey: String, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
    }

    public func fiveDay(lat: Double, lon: Double) async throws -> [ForecastDay] {
        var comps = URLComponents(string: "https://api.openweathermap.org/data/2.5/forecast")!
        comps.queryItems = [
            .init(name: "lat", value: String(lat)),
            .init(name: "lon", value: String(lon)),
            .init(name: "appid", value: apiKey)
        ]

        let (data, resp) = try await session.data(from: comps.url!)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }

        let decoded = try JSONDecoder().decode(OWForecastResponse.self, from: data)
        return Self.aggregateToDays(items: decoded.list)
    }

    // Group 3h items into day buckets -> min/max temp (K→C), max rain chance
    private static func aggregateToDays(items: [OWForecastResponse.Item]) -> [ForecastDay] {
        var buckets: [Date: [OWForecastResponse.Item]] = [:]
        let cal = Calendar.current

        for it in items {
            let d = Date(timeIntervalSince1970: it.dt)
            let day = cal.startOfDay(for: d)
            buckets[day, default: []].append(it)
        }

        let days = buckets.keys.sorted()
        var result: [ForecastDay] = []
        for day in days.prefix(5) {
            guard let bucket = buckets[day] else { continue }
            let minK = bucket.map { $0.main.temp_min }.min() ?? 0
            let maxK = bucket.map { $0.main.temp_max }.max() ?? 0
            let pop = Int(((bucket.compactMap { $0.pop }.max() ?? 0) * 100).rounded())
            let summary = bucket.first?.weather.first?.description.capitalized ?? ""
            result.append(
                ForecastDay(
                    date: day,
                    minC: minK - 273.15,
                    maxC: maxK - 273.15,
                    rainChance: pop,
                    summary: summary
                )
            )
        }
        return result
    }
}

// Mock
public struct MockForecastService: ForecastServicing {
    public init() {}
    public func fiveDay(lat: Double, lon: Double) async throws -> [ForecastDay] {
        let now = Calendar.current.startOfDay(for: Date())
        return (0..<5).map { i in
            ForecastDay(
                date: Calendar.current.date(byAdding: .day, value: i, to: now)!,
                minC: 22 + Double(i),
                maxC: 31 + Double(i),
                rainChance: [10, 30, 60, 20, 0][i % 5],
                summary: ["Clear", "Clouds", "Rain", "Partly Cloudy", "Clear"][i % 5]
            )
        }
    }
}
