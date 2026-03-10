import Foundation
import CoreLocation

class WatchLocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()

    @Published var location: CLLocation?
    @Published var locationName: String?
    @Published var didFail: Bool = false

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func requestLocation() {
        let status = manager.authorizationStatus
        if status == .notDetermined {
            manager.requestWhenInUseAuthorization()
        } else if status == .authorizedWhenInUse || status == .authorizedAlways {
            manager.requestLocation()
        } else {
            // Denied/restricted — try saved fallback
            useFallbackLocation()
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            manager.requestLocation()
        } else if status == .denied || status == .restricted {
            useFallbackLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        location = loc
        reverseGeocode(loc)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        didFail = true
        useFallbackLocation()
    }

    private func useFallbackLocation() {
        didFail = true
        let defaults = UserDefaults(suiteName: "group.com.sunscreenfyi.shared")
        if let lat = defaults?.object(forKey: "lastLatitude") as? Double,
           let lon = defaults?.object(forKey: "lastLongitude") as? Double {
            location = CLLocation(latitude: lat, longitude: lon)
        }
    }

    private func reverseGeocode(_ location: CLLocation) {
        CLGeocoder().reverseGeocodeLocation(location) { [weak self] placemarks, _ in
            guard let placemark = placemarks?.first else { return }
            if let city = placemark.locality, let state = placemark.administrativeArea {
                self?.locationName = "\(city), \(state)"
            } else if let city = placemark.locality {
                self?.locationName = city
            }
        }
    }
}
