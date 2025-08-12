import Foundation
import CoreLocation

@MainActor
public final class WeatherViewModel: ObservableObject {
    // UI state
    @Published public private(set) var weather: Weather?
    @Published public private(set) var forecast: [ForecastDay] = []
    @Published public private(set) var suggestions: [Suggestion] = []
    @Published public private(set) var isLoading = false
    @Published public private(set) var errorMessage: String?
    @Published public private(set) var lastUpdated: Date?
    @Published public private(set) var selectedPlaceName: String?
    @Published public private(set) var isUsingCurrentLocation = true

    // Dependencies
    private let service: WeatherServicing
    private let forecastService: ForecastServicing
    private let location: LocationProviding
    private let suggester: SuggestionEngine

    private var inFlightTask: Task<Void, Never>?

    public init(
        service: WeatherServicing,
        forecastService: ForecastServicing,
        location: LocationProviding,
        suggester: SuggestionEngine = RuleBasedSuggestionEngine()
    ) {
        self.service = service
        self.forecastService = forecastService
        self.location = location
        self.suggester = suggester
    }

    // MARK: - Current device location
    public func refresh() {
        isUsingCurrentLocation = true
        selectedPlaceName = nil
        startFetch {
            let coord = try await self.location.requestOnce()
            return try await self.fetchAll(at: coord)
        }
    }

    // MARK: - Searched coordinate
    public func refresh(for coordinate: CLLocationCoordinate2D, placeName: String? = nil) {
        isUsingCurrentLocation = false
        selectedPlaceName = placeName
        startFetch {
            try await self.fetchAll(at: coordinate)
        }
    }

    // MARK: - Internals
    private func fetchAll(at coord: CLLocationCoordinate2D) async throws -> Weather {
        let w = try await service.currentWeather(lat: coord.latitude, lon: coord.longitude)
        let f = try await forecastService.fiveDay(lat: coord.latitude, lon: coord.longitude)
        self.forecast = f
        self.suggestions = suggester.make(weather: w, forecast: f)
        return w
    }

    private func startFetch(_ work: @escaping () async throws -> Weather) {
        inFlightTask?.cancel()
        isLoading = true
        errorMessage = nil

        inFlightTask = Task { [weak self] in
            guard let self else { return }
            do {
                let w = try await work()
                guard !Task.isCancelled else { return }
                self.weather = w
                self.lastUpdated = Date()
            } catch {
                guard !Task.isCancelled else { return }
                self.errorMessage = self.friendly(error)
                self.forecast = []
                self.suggestions = []
            }
            self.isLoading = false
        }
    }

    private func friendly(_ error: Error) -> String {
        switch error {
        case is CLError:  return "Location permission denied or unavailable."
        case is URLError: return "Network issue. Please try again."
        default:          return "Something went wrong. Please try again."
        }
    }
}
