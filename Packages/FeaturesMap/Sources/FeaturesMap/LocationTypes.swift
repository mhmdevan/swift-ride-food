import CoreLocation

public enum LocationPermissionStatus: Equatable, Sendable {
    case notDetermined
    case authorized
    case denied
    case restricted
}

public struct LocationCoordinate: Equatable, Sendable {
    public let latitude: Double
    public let longitude: Double

    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }

    public var clCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    static func from(_ coordinate: CLLocationCoordinate2D) -> LocationCoordinate {
        LocationCoordinate(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }
}
