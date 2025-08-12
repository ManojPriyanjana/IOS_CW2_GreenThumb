import Foundation

// MARK: - Types

public struct Suggestion: Identifiable, Equatable {
    public enum Kind { case water, heat, cold, disease, wind, rain }
    public let id = UUID()
    public let kind: Kind
    public let title: String
    public let detail: String
    public let priority: Int
}

public protocol SuggestionEngine {
    func make(weather: Weather, forecast: [ForecastDay]) -> [Suggestion]
}

// MARK: - Rules (easier thresholds + friendly fallback)

public struct RuleBasedSuggestionEngine: SuggestionEngine {
    public init() {}

    public func make(weather w: Weather, forecast f: [ForecastDay]) -> [Suggestion] {
        var out: [Suggestion] = []

        // Easier thresholds so tips show up more often (great for demos)
        if w.temperatureC >= 30 {
            out.append(.init(kind: .heat,
                             title: "Warm day ahead",
                             detail: "Water after sunset to reduce stress and evaporation.",
                             priority: 95))
        }
        if w.temperatureC <= 14 {
            out.append(.init(kind: .cold,
                             title: "Cool conditions",
                             detail: "Protect tender plants or move pots indoors overnight.",
                             priority: 90))
        }
        if let h = w.humidity, h >= 70 {
            out.append(.init(kind: .disease,
                             title: "Humidity is high",
                             detail: "Increase airflow; check leaves for early fungus spots.",
                             priority: 85))
        }
        if let wind = w.windSpeed, wind >= 6 {
            out.append(.init(kind: .wind,
                             title: "Breezy day",
                             detail: "Stake tall plants and postpone foliar spraying.",
                             priority: 70))
        }
        if let today = f.first, today.rainChance >= 40 {
            out.append(.init(kind: .rain,
                             title: "Rain possible today",
                             detail: "Consider skipping watering to prevent overwatering.",
                             priority: 92))
        }

        // Fallback so the section never looks empty
        if out.isEmpty {
            out.append(.init(kind: .water,
                             title: "No special actions today",
                             detail: "Maintain regular watering and check soil moisture.",
                             priority: 10))
        }

        return out.sorted { $0.priority > $1.priority }
    }
}
