import Foundation

public protocol RouteProviding: Sendable {
    func route(from: LocationCoordinate, to: LocationCoordinate) async throws -> [LocationCoordinate]
}

public struct MockPolylineRouteProvider: RouteProviding {
    private let interpolationPoints: Int

    public init(interpolationPoints: Int = 20) {
        self.interpolationPoints = max(2, interpolationPoints)
    }

    public func route(from: LocationCoordinate, to: LocationCoordinate) async throws -> [LocationCoordinate] {
        // Intentional GCD usage: route interpolation runs off-main for legacy awareness.
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let points: [LocationCoordinate] = (0 ... self.interpolationPoints).map { index in
                    let progress = Double(index) / Double(self.interpolationPoints)
                    let latitude = from.latitude + (to.latitude - from.latitude) * progress
                    let longitude = from.longitude + (to.longitude - from.longitude) * progress
                    return LocationCoordinate(latitude: latitude, longitude: longitude)
                }

                continuation.resume(returning: points)
            }
        }
    }
}
