import Analytics
import FeaturesAuth
import FeaturesCatalogUIKit
import FeaturesHome
import Foundation
import FeaturesMap
import FeaturesOrders
import SwiftUI

@MainActor
final class AppCoordinator: ObservableObject {
    @Published var path: [AppRoute] = []

    private struct DeepLinkContext {
        let scheme: String
        let host: String
        let pathShape: String
    }

    let dependencyContainer: AppDependencyContainer
    let homeViewModel: HomeViewModel
    private let offersDeepLinkParser: any OffersDeepLinkParsing
    private var pendingAuthenticatedRoute: AppRoute?

    init(
        dependencyContainer: AppDependencyContainer = AppDependencyContainer(),
        offersDeepLinkParser: any OffersDeepLinkParsing = OffersDeepLinkParser()
    ) {
        self.dependencyContainer = dependencyContainer
        self.homeViewModel = dependencyContainer.makeHomeViewModel()
        self.offersDeepLinkParser = offersDeepLinkParser
    }

    func handleHomeAction(_ destination: HomeDestination) {
        switch destination {
        case .auth:
            path.append(.auth)
            trackScreenView(name: ObservabilityEventName.Screen.authViewed)
        case .map:
            path.append(.map)
            trackScreenView(name: ObservabilityEventName.Screen.mapViewed)
        case .orders:
            path.append(.orders)
            trackScreenView(name: ObservabilityEventName.Screen.ordersViewed)
        case .catalog:
            path.append(.catalog)
            trackScreenView(name: ObservabilityEventName.Screen.offersFeedViewed)
        }
    }

    func resetNavigation() {
        path.removeAll()
        pendingAuthenticatedRoute = nil
    }

    func reloadHomeDestinations() {
        homeViewModel.updateActions(dependencyContainer.availableHomeDestinations())
    }

    @discardableResult
    func handleIncomingURL(_ url: URL, isAuthenticated: Bool) -> OffersDeepLinkRoutingResult {
        let parseResult = offersDeepLinkParser.parse(url)

        switch parseResult {
        case .notApplicable:
            trackDeepLinkIgnored(url: url)
            return .notHandled
        case .failure(let reason):
            trackDeepLinkFailure(reason: reason, url: url)
            return .failed(reason)
        case .target(let target):
            if isAuthenticated {
                routeToOfferDetail(target.offerID)
                trackDeepLinkRouted(target: target, authRequired: false)
                return .routed(offerID: target.offerID)
            }

            pendingAuthenticatedRoute = .offerDetail(id: target.offerID)
            trackDeepLinkRouted(target: target, authRequired: true)
            return .requiresAuthentication(offerID: target.offerID)
        }
    }

    @discardableResult
    func consumePendingRouteAfterAuthenticationIfNeeded() -> Bool {
        guard let pendingRoute = pendingAuthenticatedRoute else {
            return false
        }

        pendingAuthenticatedRoute = nil

        switch pendingRoute {
        case .offerDetail(let id):
            routeToOfferDetail(id)
            return true
        case .auth, .map, .orders, .catalog:
            return false
        }
    }

    private func routeToOfferDetail(_ offerID: UUID) {
        path = [.catalog, .offerDetail(id: offerID)]
        trackScreenView(name: ObservabilityEventName.Screen.offersFeedViewed)
        trackScreenView(
            name: ObservabilityEventName.Screen.offerDetailViewed,
            parameters: ["offer_id": offerID.uuidString.lowercased()]
        )
    }

    private func trackDeepLinkRouted(target: OffersDeepLinkTarget, authRequired: Bool) {
        let eventName = authRequired
            ? ObservabilityEventName.DeepLink.requiresAuth
            : ObservabilityEventName.DeepLink.routed
        let tracker = dependencyContainer.analyticsTracker
        let crashReporter = dependencyContainer.crashReporter
        let rumMonitor = dependencyContainer.rumMonitor
        Task {
            await tracker.track(
                AnalyticsEvent(
                    name: eventName,
                    parameters: [
                        "source": target.source.rawValue,
                        "offer_id": target.offerID.uuidString.lowercased()
                    ]
                )
            )
            await crashReporter.addBreadcrumb(
                CrashBreadcrumb(
                    message: "Offers deep link routed",
                    category: "deep_link",
                    metadata: [
                        "source": target.source.rawValue,
                        "offer_id": target.offerID.uuidString.lowercased(),
                        "auth_required": authRequired ? "true" : "false"
                    ]
                )
            )
            rumMonitor.trackAction(
                name: eventName,
                attributes: [
                    "source": target.source.rawValue,
                    "offer_id": target.offerID.uuidString.lowercased(),
                    "auth_required": authRequired ? "true" : "false"
                ]
            )
        }
    }

    private func trackDeepLinkFailure(reason: OffersDeepLinkFailureReason, url: URL) {
        let tracker = dependencyContainer.analyticsTracker
        let crashReporter = dependencyContainer.crashReporter
        let rumMonitor = dependencyContainer.rumMonitor
        let context = safeDeepLinkContext(from: url)
        Task {
            await tracker.track(
                AnalyticsEvent(
                    name: ObservabilityEventName.DeepLink.failed,
                    parameters: [
                        "reason": reason.rawValue,
                        "scheme": context.scheme,
                        "host": context.host,
                        "path_shape": context.pathShape
                    ]
                )
            )
            await crashReporter.addBreadcrumb(
                CrashBreadcrumb(
                    message: "Offers deep link rejected",
                    category: "deep_link",
                    metadata: [
                        "reason": reason.rawValue,
                        "scheme": context.scheme,
                        "host": context.host,
                        "path_shape": context.pathShape
                    ]
                )
            )
            rumMonitor.trackError(
                name: ObservabilityEventName.DeepLink.failed,
                reason: reason.rawValue,
                attributes: [
                    "scheme": context.scheme,
                    "host": context.host,
                    "path_shape": context.pathShape
                ]
            )
        }
    }

    private func trackDeepLinkIgnored(url: URL) {
        let tracker = dependencyContainer.analyticsTracker
        let rumMonitor = dependencyContainer.rumMonitor
        let context = safeDeepLinkContext(from: url)
        Task {
            await tracker.track(
                AnalyticsEvent(
                    name: ObservabilityEventName.DeepLink.ignored,
                    parameters: [
                        "scheme": context.scheme,
                        "host": context.host,
                        "path_shape": context.pathShape
                    ]
                )
            )
            rumMonitor.trackAction(
                name: ObservabilityEventName.DeepLink.ignored,
                attributes: [
                    "scheme": context.scheme,
                    "host": context.host,
                    "path_shape": context.pathShape
                ]
            )
        }
    }

    private func safeDeepLinkContext(from url: URL) -> DeepLinkContext {
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let scheme = components?.scheme?.lowercased() ?? "unknown"
        let host = components?.host?.lowercased() ?? "unknown"
        let pathComponents = url.pathComponents
            .filter { $0 != "/" && $0.isEmpty == false }
        let pathShape = "\(pathComponents.count)_segments"
        return DeepLinkContext(scheme: scheme, host: host, pathShape: pathShape)
    }

    private func trackScreenView(name: String, parameters: [String: String] = [:]) {
        let tracker = dependencyContainer.analyticsTracker
        let rumMonitor = dependencyContainer.rumMonitor

        Task {
            await tracker.track(AnalyticsEvent(name: name, parameters: parameters))
            rumMonitor.trackScreen(name: name, attributes: parameters)
        }
    }

    @ViewBuilder
    func destinationView(for route: AppRoute) -> some View {
        switch route {
        case .auth:
            AuthView(viewModel: dependencyContainer.makeAuthViewModel())
        case .map:
            MapTrackingView(viewModel: dependencyContainer.makeMapViewModel())
        case .orders:
            OrdersView(viewModel: dependencyContainer.makeOrdersViewModel())
        case .catalog:
            OffersUIKitScreen(viewModel: dependencyContainer.makeOffersViewModel())
        case .offerDetail(let offerID):
            OfferDetailView(offerID: offerID)
        }
    }
}
