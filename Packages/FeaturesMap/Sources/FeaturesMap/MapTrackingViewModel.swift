import Analytics
import Core
import Data
import Foundation
import Networking

@MainActor
public final class MapTrackingViewModel: ObservableObject {
    @Published public private(set) var permissionStatus: LocationPermissionStatus
    @Published public private(set) var currentLocation: LocationCoordinate?
    @Published public private(set) var driverLocation: LocationCoordinate?
    @Published public private(set) var destinationLocation: LocationCoordinate
    @Published public private(set) var liveOrderStatus: OrderStatus?
    @Published public private(set) var routeCoordinates: [LocationCoordinate] = []
    @Published public private(set) var isRouteLoading: Bool = false
    @Published public private(set) var errorMessage: String?

    private let locationManager: any LocationManaging
    private let routeProvider: any RouteProviding
    private let liveUpdatesClient: any WebSocketClient
    private let tracker: any AnalyticsTracking
    private let crashReporter: any CrashReporting
    private let globalErrorHandler: any GlobalErrorHandling
    private let trackedOrderID: UUID

    private var hasStartedLocationUpdates = false
    private var liveUpdatesTask: Task<Void, Never>?

    public init(
        locationManager: any LocationManaging = CoreLocationManagerAdapter(),
        routeProvider: any RouteProviding = MockPolylineRouteProvider(),
        liveUpdatesClient: (any WebSocketClient)? = nil,
        trackedOrderID: UUID = UUID(uuidString: "11111111-1111-1111-1111-111111111111") ?? UUID(),
        destinationLocation: LocationCoordinate = LocationCoordinate(latitude: 55.751244, longitude: 37.618423),
        tracker: any AnalyticsTracking = NoOpAnalyticsTracker(),
        crashReporter: any CrashReporting = NoOpCrashReporter(),
        globalErrorHandler: any GlobalErrorHandling = NoOpGlobalErrorHandler()
    ) {
        self.locationManager = locationManager
        self.routeProvider = routeProvider
        self.trackedOrderID = trackedOrderID
        self.liveUpdatesClient = liveUpdatesClient
            ?? MockWebSocketClient(trackedOrderID: trackedOrderID)
        self.destinationLocation = destinationLocation
        self.tracker = tracker
        self.crashReporter = crashReporter
        self.globalErrorHandler = globalErrorHandler
        permissionStatus = locationManager.permissionStatus

        bindLocationManager()
    }

    public func onAppear() {
        handlePermissionChange(locationManager.permissionStatus)
        startLiveUpdatesIfNeeded()
    }

    public func onDisappear() {
        liveUpdatesTask?.cancel()
        liveUpdatesTask = nil

        Task {
            await liveUpdatesClient.disconnect()
            await tracker.track(AnalyticsEvent(name: "websocket_disconnected"))
        }
    }

    public func requestPermission() {
        locationManager.requestPermission()
    }

    public func retryRoute() {
        Task {
            await buildRouteIfPossible()
        }
    }

    private func startLiveUpdatesIfNeeded() {
        guard liveUpdatesTask == nil else {
            return
        }

        liveUpdatesTask = Task { [weak self] in
            guard let self else { return }

            do {
                try await self.liveUpdatesClient.connect()
                await self.tracker.track(AnalyticsEvent(name: "websocket_connected"))
                await self.crashReporter.addBreadcrumb(
                    CrashBreadcrumb(
                        message: "WebSocket connected",
                        category: "map"
                    )
                )

                let stream = await self.liveUpdatesClient.events()
                for try await event in stream {
                    await self.handleLiveUpdateEvent(event)
                }
            } catch {
                let appError = AppError.network(message: "Live updates are temporarily unavailable.")
                self.errorMessage = appError.errorDescription
                await self.tracker.track(AnalyticsEvent(name: "websocket_connection_failed"))
                await self.crashReporter.recordNonFatal(
                    error,
                    context: ["feature": "map", "action": "websocket_connect"]
                )
                self.globalErrorHandler.present(appError, source: "map_websocket_connect")
            }
        }
    }

    private func bindLocationManager() {
        locationManager.onPermissionChange = { [weak self] status in
            guard let self else { return }
            Task { @MainActor in
                self.handlePermissionChange(status)
            }
        }

        locationManager.onLocationChange = { [weak self] coordinate in
            guard let self else { return }
            Task { @MainActor in
                self.currentLocation = coordinate
                self.errorMessage = nil
                await self.tracker.track(AnalyticsEvent(name: "map_location_received"))
                await self.buildRouteIfPossible()
            }
        }

        locationManager.onError = { [weak self] message in
            guard let self else { return }
            Task { @MainActor in
                self.errorMessage = message
                await self.crashReporter.addBreadcrumb(
                    CrashBreadcrumb(
                        message: "Location manager reported error",
                        category: "map",
                        metadata: ["message": message]
                    )
                )
            }
        }
    }

    private func handlePermissionChange(_ status: LocationPermissionStatus) {
        permissionStatus = status

        switch status {
        case .authorized:
            errorMessage = nil
            guard hasStartedLocationUpdates == false else {
                return
            }
            hasStartedLocationUpdates = true
            locationManager.startUpdatingLocation()

            Task {
                await tracker.track(AnalyticsEvent(name: "location_permission_authorized"))
            }
        case .denied, .restricted:
            locationManager.stopUpdatingLocation()
            routeCoordinates = []
            errorMessage = "Location permission is denied. Please enable access in Settings."
            Task {
                await tracker.track(AnalyticsEvent(name: "location_permission_denied"))
            }
        case .notDetermined:
            errorMessage = nil
        }
    }

    private func handleLiveUpdateEvent(_ event: WebSocketEvent) async {
        switch event {
        case .orderStatusChanged(let orderID, let status):
            guard orderID == trackedOrderID,
                  let mappedStatus = mapOrderStatus(status) else {
                return
            }

            liveOrderStatus = mappedStatus
            await tracker.track(
                AnalyticsEvent(
                    name: "order_status_changed",
                    parameters: ["status": mappedStatus.rawValue]
                )
            )
            await tracker.track(
                AnalyticsEvent(
                    name: "order_status_viewed",
                    parameters: ["status": mappedStatus.rawValue]
                )
            )
            await crashReporter.addBreadcrumb(
                CrashBreadcrumb(
                    message: "Order status updated",
                    category: "map",
                    metadata: ["status": mappedStatus.rawValue]
                )
            )

        case .driverLocationChanged(let orderID, let latitude, let longitude):
            guard orderID == trackedOrderID else {
                return
            }

            driverLocation = LocationCoordinate(latitude: latitude, longitude: longitude)
            await tracker.track(AnalyticsEvent(name: "driver_location_changed"))
            await buildRouteIfPossible()
        }
    }

    private func buildRouteIfPossible() async {
        guard permissionStatus == .authorized else {
            return
        }

        guard let sourceLocation = driverLocation ?? currentLocation else {
            return
        }

        isRouteLoading = true
        defer { isRouteLoading = false }

        do {
            let route = try await routeProvider.route(from: sourceLocation, to: destinationLocation)
            routeCoordinates = route
            await tracker.track(AnalyticsEvent(name: "route_polyline_drawn", parameters: ["points": "\(route.count)"]))
        } catch {
            let appError = AppError.network(message: "Unable to build route. Please try again.")
            errorMessage = appError.errorDescription
            await crashReporter.recordNonFatal(
                error,
                context: ["feature": "map", "action": "build_route"]
            )
            globalErrorHandler.present(appError, source: "map_build_route")
        }
    }

    private func mapOrderStatus(_ rawValue: String) -> OrderStatus? {
        switch rawValue {
        case "pending":
            return .pending
        case "in_progress", "inProgress":
            return .inProgress
        case "completed":
            return .completed
        case "cancelled":
            return .cancelled
        default:
            return nil
        }
    }
}
