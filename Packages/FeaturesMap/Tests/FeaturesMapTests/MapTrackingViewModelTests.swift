import Analytics
import Data
import Foundation
import Networking
import Testing
@testable import FeaturesMap

private final class MockLocationManager: LocationManaging {
    var permissionStatus: LocationPermissionStatus
    var onPermissionChange: ((LocationPermissionStatus) -> Void)?
    var onLocationChange: ((LocationCoordinate) -> Void)?
    var onError: ((String) -> Void)?

    private(set) var requestPermissionCallCount: Int = 0
    private(set) var startUpdatingCallCount: Int = 0

    init(permissionStatus: LocationPermissionStatus) {
        self.permissionStatus = permissionStatus
    }

    func requestPermission() {
        requestPermissionCallCount += 1
    }

    func startUpdatingLocation() {
        startUpdatingCallCount += 1
    }

    func stopUpdatingLocation() {}

    func sendPermission(_ status: LocationPermissionStatus) {
        permissionStatus = status
        onPermissionChange?(status)
    }

    func sendLocation(_ coordinate: LocationCoordinate) {
        onLocationChange?(coordinate)
    }

    func sendError(_ message: String) {
        onError?(message)
    }
}

private struct StaticRouteProvider: RouteProviding {
    let result: Result<[LocationCoordinate], Error>

    func route(from: LocationCoordinate, to: LocationCoordinate) async throws -> [LocationCoordinate] {
        _ = from
        _ = to
        return try result.get()
    }
}

private struct RouteBuildError: Error {}

private actor NoOpWebSocketClient: WebSocketClient {
    func connect() async throws {}

    func disconnect() async {}

    func events() async -> AsyncThrowingStream<WebSocketEvent, Error> {
        AsyncThrowingStream { continuation in
            continuation.finish()
        }
    }
}

private actor ControllableWebSocketClient: WebSocketClient {
    private var continuation: AsyncThrowingStream<WebSocketEvent, Error>.Continuation?

    func connect() async throws {}

    func disconnect() async {
        continuation?.finish()
    }

    func events() async -> AsyncThrowingStream<WebSocketEvent, Error> {
        AsyncThrowingStream { continuation in
            self.continuation = continuation
        }
    }

    func send(_ event: WebSocketEvent) {
        continuation?.yield(event)
    }
}

private actor SpyWebSocketClient: WebSocketClient {
    private(set) var connectCallCount: Int = 0
    private(set) var disconnectCallCount: Int = 0

    func connect() async throws {
        connectCallCount += 1
    }

    func disconnect() async {
        disconnectCallCount += 1
    }

    func events() async -> AsyncThrowingStream<WebSocketEvent, Error> {
        AsyncThrowingStream { _ in }
    }

    func observedDisconnectCallCount() -> Int {
        disconnectCallCount
    }
}

@MainActor
@Test
func onAppearWithDeniedPermissionShowsErrorState() {
    let locationManager = MockLocationManager(permissionStatus: .denied)
    let routeProvider = StaticRouteProvider(result: .success([]))
    let viewModel = MapTrackingViewModel(
        locationManager: locationManager,
        routeProvider: routeProvider,
        liveUpdatesClient: NoOpWebSocketClient()
    )

    viewModel.onAppear()

    #expect(viewModel.permissionStatus == .denied)
    #expect(viewModel.errorMessage?.contains("denied") == true)
}

@MainActor
@Test
func requestPermissionDelegatesToLocationManager() {
    let locationManager = MockLocationManager(permissionStatus: .notDetermined)
    let routeProvider = StaticRouteProvider(result: .success([]))
    let viewModel = MapTrackingViewModel(
        locationManager: locationManager,
        routeProvider: routeProvider,
        liveUpdatesClient: NoOpWebSocketClient()
    )

    viewModel.requestPermission()

    #expect(locationManager.requestPermissionCallCount == 1)
}

@MainActor
@Test
func authorizedPermissionAndLocationUpdateBuildsPolyline() async throws {
    let locationManager = MockLocationManager(permissionStatus: .authorized)
    let expectedRoute = [
        LocationCoordinate(latitude: 55.75, longitude: 37.61),
        LocationCoordinate(latitude: 55.76, longitude: 37.62)
    ]
    let routeProvider = StaticRouteProvider(result: .success(expectedRoute))
    let viewModel = MapTrackingViewModel(
        locationManager: locationManager,
        routeProvider: routeProvider,
        liveUpdatesClient: NoOpWebSocketClient()
    )

    viewModel.onAppear()
    locationManager.sendLocation(LocationCoordinate(latitude: 55.75, longitude: 37.61))
    try await Task.sleep(nanoseconds: 40_000_000)

    #expect(locationManager.startUpdatingCallCount == 1)
    #expect(viewModel.routeCoordinates == expectedRoute)
}

@MainActor
@Test
func routeFailureShowsErrorMessage() async throws {
    let locationManager = MockLocationManager(permissionStatus: .authorized)
    let routeProvider = StaticRouteProvider(result: .failure(RouteBuildError()))
    let viewModel = MapTrackingViewModel(
        locationManager: locationManager,
        routeProvider: routeProvider,
        liveUpdatesClient: NoOpWebSocketClient()
    )

    viewModel.onAppear()
    locationManager.sendLocation(LocationCoordinate(latitude: 55.75, longitude: 37.61))
    try await Task.sleep(nanoseconds: 40_000_000)

    #expect(viewModel.errorMessage == "Unable to build route. Please try again.")
}

@MainActor
@Test
func websocketOrderStatusEventUpdatesLiveStatus() async throws {
    let trackedOrderID = try #require(UUID(uuidString: "11111111-1111-1111-1111-111111111111"))
    let webSocketClient = ControllableWebSocketClient()
    let viewModel = MapTrackingViewModel(
        locationManager: MockLocationManager(permissionStatus: .notDetermined),
        routeProvider: StaticRouteProvider(result: .success([])),
        liveUpdatesClient: webSocketClient,
        trackedOrderID: trackedOrderID
    )

    viewModel.onAppear()
    try await Task.sleep(nanoseconds: 30_000_000)

    await webSocketClient.send(.orderStatusChanged(orderID: trackedOrderID, status: "in_progress"))
    try await Task.sleep(nanoseconds: 30_000_000)

    #expect(viewModel.liveOrderStatus == .inProgress)
}

@MainActor
@Test
func websocketOrderStatusEventTracksOrderStatusViewedAnalytics() async throws {
    let trackedOrderID = try #require(UUID(uuidString: "11111111-1111-1111-1111-111111111111"))
    let webSocketClient = ControllableWebSocketClient()
    let analyticsTracker = InMemoryAnalyticsTracker()
    let viewModel = MapTrackingViewModel(
        locationManager: MockLocationManager(permissionStatus: .notDetermined),
        routeProvider: StaticRouteProvider(result: .success([])),
        liveUpdatesClient: webSocketClient,
        trackedOrderID: trackedOrderID,
        tracker: analyticsTracker
    )

    viewModel.onAppear()
    try await Task.sleep(nanoseconds: 30_000_000)

    await webSocketClient.send(.orderStatusChanged(orderID: trackedOrderID, status: "completed"))
    try await Task.sleep(nanoseconds: 30_000_000)

    let events = await analyticsTracker.trackedEvents()
    #expect(events.contains(where: { $0.name == "order_status_viewed" }))
}

@MainActor
@Test
func websocketDriverLocationEventUpdatesDriverAndRoute() async throws {
    let trackedOrderID = try #require(UUID(uuidString: "11111111-1111-1111-1111-111111111111"))
    let webSocketClient = ControllableWebSocketClient()
    let expectedRoute = [
        LocationCoordinate(latitude: 55.752, longitude: 37.616),
        LocationCoordinate(latitude: 55.751, longitude: 37.618)
    ]
    let viewModel = MapTrackingViewModel(
        locationManager: MockLocationManager(permissionStatus: .authorized),
        routeProvider: StaticRouteProvider(result: .success(expectedRoute)),
        liveUpdatesClient: webSocketClient,
        trackedOrderID: trackedOrderID,
        destinationLocation: LocationCoordinate(latitude: 55.751, longitude: 37.618)
    )

    viewModel.onAppear()
    try await Task.sleep(nanoseconds: 30_000_000)

    await webSocketClient.send(
        .driverLocationChanged(
            orderID: trackedOrderID,
            latitude: 55.752,
            longitude: 37.616
        )
    )
    try await Task.sleep(nanoseconds: 30_000_000)

    #expect(viewModel.driverLocation == LocationCoordinate(latitude: 55.752, longitude: 37.616))
    #expect(viewModel.routeCoordinates == expectedRoute)
}

@MainActor
@Test
func onDisappearDisconnectsLiveUpdatesClient() async throws {
    let webSocketClient = SpyWebSocketClient()
    let viewModel = MapTrackingViewModel(
        locationManager: MockLocationManager(permissionStatus: .notDetermined),
        routeProvider: StaticRouteProvider(result: .success([])),
        liveUpdatesClient: webSocketClient
    )

    viewModel.onAppear()
    try await Task.sleep(nanoseconds: 30_000_000)

    viewModel.onDisappear()
    try await Task.sleep(nanoseconds: 30_000_000)

    #expect(await webSocketClient.observedDisconnectCallCount() == 1)
}
