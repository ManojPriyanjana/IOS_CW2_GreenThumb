import Foundation

public protocol ForecastServicing {
    func fiveDay(lat: Double, lon: Double) async throws -> [ForecastDay]
}
