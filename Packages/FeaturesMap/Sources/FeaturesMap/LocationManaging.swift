public protocol LocationManaging: AnyObject {
    var permissionStatus: LocationPermissionStatus { get }
    var onPermissionChange: ((LocationPermissionStatus) -> Void)? { get set }
    var onLocationChange: ((LocationCoordinate) -> Void)? { get set }
    var onError: ((String) -> Void)? { get set }

    func requestPermission()
    func startUpdatingLocation()
    func stopUpdatingLocation()
}
