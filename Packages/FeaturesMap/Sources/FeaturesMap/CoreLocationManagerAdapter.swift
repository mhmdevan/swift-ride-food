import CoreLocation
import Foundation

public final class CoreLocationManagerAdapter: NSObject, LocationManaging {
    public var onPermissionChange: ((LocationPermissionStatus) -> Void)?
    public var onLocationChange: ((LocationCoordinate) -> Void)?
    public var onError: ((String) -> Void)?

    public var permissionStatus: LocationPermissionStatus {
        Self.map(status: locationManager.authorizationStatus)
    }

    private let locationManager: CLLocationManager

    public override init() {
        locationManager = CLLocationManager()
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }

    public func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    public func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
    }

    public func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }

    private static func map(status: CLAuthorizationStatus) -> LocationPermissionStatus {
        switch status {
        case .notDetermined:
            return .notDetermined
        case .restricted:
            return .restricted
        case .denied:
            return .denied
        case .authorizedAlways, .authorizedWhenInUse:
            return .authorized
        @unknown default:
            return .denied
        }
    }
}

extension CoreLocationManagerAdapter: CLLocationManagerDelegate {
    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let mapped = Self.map(status: manager.authorizationStatus)
        onPermissionChange?(mapped)
    }

    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let coordinate = locations.last?.coordinate else {
            return
        }

        let mapped = LocationCoordinate.from(coordinate)
        onLocationChange?(mapped)
    }

    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        onError?(error.localizedDescription)
    }
}
