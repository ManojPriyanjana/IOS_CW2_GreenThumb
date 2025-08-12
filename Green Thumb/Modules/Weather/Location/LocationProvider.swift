import CoreLocation
import Foundation

public protocol LocationProviding {
    func requestOnce() async throws -> CLLocationCoordinate2D
}

public final class LocationProvider: NSObject, LocationProviding {
    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<CLLocationCoordinate2D, Error>?

    public override init() {
        super.init()
        manager.delegate = self
    }

    public func requestOnce() async throws -> CLLocationCoordinate2D {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            throw CLError(.denied)
        default: break
        }

        return try await withCheckedThrowingContinuation { [weak self] cc in
            guard let self else { cc.resume(throwing: URLError(.unknown)); return }
            self.continuation = cc
            self.manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
            self.manager.requestLocation()
        }
    }
}

extension LocationProvider: CLLocationManagerDelegate {
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let coord = locations.first?.coordinate {
            continuation?.resume(returning: coord)
        } else {
            continuation?.resume(throwing: CLError(.locationUnknown))
        }
        continuation = nil
    }

    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        continuation?.resume(throwing: error)
        continuation = nil
    }
}

// Mock for previews/tests
public struct MockLocationProvider: LocationProviding {
    public init() {}
    public func requestOnce() async throws -> CLLocationCoordinate2D {
        .init(latitude: 6.9271, longitude: 79.8612) // Colombo
    }
}
