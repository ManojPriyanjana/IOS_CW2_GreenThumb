import Foundation
import MapKit
import CoreLocation

final class StoreLocatorViewModel: NSObject, ObservableObject {
    // Default to Colombo so the map isn’t empty on first launch
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 6.9271, longitude: 79.8612),
        span: MKCoordinateSpan(latitudeDelta: 0.15, longitudeDelta: 0.15)
    )

    @Published var results: [Place] = []
    @Published var statusMessage: String? = nil
    @Published var authorizationDenied = false

    private let locationManager = CLLocationManager()

    override init() {
        super.init()
        locationManager.delegate = self
    }

    func requestLocation() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        case .denied, .restricted:
            authorizationDenied = true
        @unknown default:
            break
        }
    }

    func searchNearby(_ query: String) {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.region = region

        let search = MKLocalSearch(request: request)
        search.start { [weak self] response, error in
            guard let self = self else { return }
            if let error = error {
                self.statusMessage = "Search failed: \(error.localizedDescription)"
                self.results = []
                return
            }
            let items = response?.mapItems ?? []
            self.results = items.map { Place(item: $0) }
            self.statusMessage = self.results.isEmpty ? "No results found." : nil
        }
    }
}

extension StoreLocatorViewModel: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        requestLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        region = MKCoordinateRegion(
            center: loc.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
        )
        // Kick off a first search near the user
        searchNearby("plant nursery")
        manager.stopUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        statusMessage = "Location error: \(error.localizedDescription)"
    }
}
