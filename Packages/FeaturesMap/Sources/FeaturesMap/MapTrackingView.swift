import DesignSystem
import Data
import MapKit
import SwiftUI

public struct MapTrackingView: View {
    @ObservedObject private var viewModel: MapTrackingViewModel
    @State private var cameraPosition: MapCameraPosition = .automatic

    public init(viewModel: MapTrackingViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text("Live Map Tracking")
                .font(AppTypography.heading)
                .foregroundStyle(AppColors.textPrimary)
                .accessibilityLabel("map_title")
                .accessibilityAddTraits(.isHeader)

            content

            if let status = viewModel.liveOrderStatus {
                Text("Live Status: \(formattedStatus(status))")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textPrimary)
                    .accessibilityLabel("live_order_status")
            }

            if let errorMessage = viewModel.errorMessage, viewModel.permissionStatus == .authorized {
                StateFeedbackView(kind: .error(message: errorMessage))
                    .accessibilityLabel("map_error_message")
            }
        }
        .padding(AppSpacing.large)
        .background(AppColors.background)
        .onAppear {
            viewModel.onAppear()
        }
        .onDisappear {
            viewModel.onDisappear()
        }
        .onChange(of: viewModel.currentLocation) { _, _ in
            updateCamera()
        }
        .onChange(of: viewModel.routeCoordinates) { _, _ in
            updateCamera()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.permissionStatus {
        case .notDetermined:
            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                StateFeedbackView(kind: .empty(message: "Allow location access to start map tracking"))
                    .accessibilityLabel("location_permission_not_determined")

                PrimaryActionButton(title: "Allow Location") {
                    viewModel.requestPermission()
                }
                .accessibilityLabel("allow_location_button")
                .accessibilityHint("Requests location access")
            }
        case .denied, .restricted:
            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                StateFeedbackView(kind: .error(message: "Location access is denied. Enable it in Settings and try again."))
                    .accessibilityLabel("location_permission_denied")

                PrimaryActionButton(title: "Retry Permission") {
                    viewModel.requestPermission()
                }
                .accessibilityLabel("retry_permission_button")
                .accessibilityHint("Try location permission again")
            }
        case .authorized:
            mapContent
        }
    }

    private var mapContent: some View {
        ZStack(alignment: .topLeading) {
            Map(position: $cameraPosition) {
                if let current = viewModel.currentLocation {
                    Annotation("You", coordinate: current.clCoordinate) {
                        Image(systemName: "location.circle.fill")
                            .foregroundStyle(AppColors.brand)
                    }
                }

                if let driver = viewModel.driverLocation {
                    Annotation("Driver", coordinate: driver.clCoordinate) {
                        Image(systemName: "car.fill")
                            .foregroundStyle(.orange)
                    }
                }

                Annotation("Destination", coordinate: viewModel.destinationLocation.clCoordinate) {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundStyle(.red)
                }

                if viewModel.routeCoordinates.count >= 2 {
                    MapPolyline(coordinates: viewModel.routeCoordinates.map(\.clCoordinate))
                        .stroke(AppColors.brand, lineWidth: 5)
                }
            }
            .frame(minHeight: 280)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .accessibilityLabel("live_map_view")
            .accessibilityHint("Shows your location, driver, destination and route")

            if let status = viewModel.liveOrderStatus {
                Text("Status: \(formattedStatus(status))")
                    .font(AppTypography.caption)
                    .padding(.horizontal, AppSpacing.small)
                    .padding(.vertical, AppSpacing.xSmall)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .padding(AppSpacing.small)
                    .accessibilityLabel("live_order_status_badge")
            }

            if viewModel.isRouteLoading {
                StateFeedbackView(kind: .loading)
                    .padding(AppSpacing.small)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .padding(AppSpacing.small)
                    .accessibilityLabel("route_loading_overlay")
            }

            if viewModel.routeCoordinates.isEmpty, viewModel.isRouteLoading == false {
                VStack(alignment: .leading, spacing: AppSpacing.small) {
                    StateFeedbackView(kind: .empty(message: "Waiting for location and live updates..."))

                    PrimaryActionButton(title: "Rebuild Route") {
                        viewModel.retryRoute()
                    }
                    .accessibilityLabel("rebuild_route_button")
                    .accessibilityHint("Recalculate route polyline")
                }
                .padding(AppSpacing.small)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(AppSpacing.small)
            }
        }
    }

    private func updateCamera() {
        let points: [CLLocationCoordinate2D]

        if viewModel.routeCoordinates.count >= 2 {
            points = viewModel.routeCoordinates.map(\.clCoordinate)
        } else if let driver = viewModel.driverLocation {
            points = [driver.clCoordinate, viewModel.destinationLocation.clCoordinate]
        } else if let current = viewModel.currentLocation {
            points = [current.clCoordinate, viewModel.destinationLocation.clCoordinate]
        } else {
            points = [viewModel.destinationLocation.clCoordinate]
        }

        guard points.isEmpty == false else {
            return
        }

        if points.count == 1, let point = points.first {
            cameraPosition = .region(
                MKCoordinateRegion(
                    center: point,
                    span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                )
            )
            return
        }

        let latitudes = points.map(\.latitude)
        let longitudes = points.map(\.longitude)

        guard let minLat = latitudes.min(),
              let maxLat = latitudes.max(),
              let minLon = longitudes.min(),
              let maxLon = longitudes.max() else {
            return
        }

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )

        let span = MKCoordinateSpan(
            latitudeDelta: max((maxLat - minLat) * 1.6, 0.01),
            longitudeDelta: max((maxLon - minLon) * 1.6, 0.01)
        )

        cameraPosition = .region(MKCoordinateRegion(center: center, span: span))
    }

    private func formattedStatus(_ status: OrderStatus) -> String {
        switch status {
        case .pending:
            return "Pending"
        case .inProgress:
            return "In Progress"
        case .completed:
            return "Completed"
        case .cancelled:
            return "Cancelled"
        }
    }
}
