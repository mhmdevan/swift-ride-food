import Analytics
import DesignSystem
import FeaturesAuth
import FeaturesHome
import SwiftUI

struct RootView: View {
    @Environment(\.scenePhase) private var scenePhase

    private let dependencyContainer: AppDependencyContainer
    @StateObject private var coordinator: AppCoordinator
    @StateObject private var sessionViewModel: SessionViewModel
    @StateObject private var authViewModel: AuthViewModel
    @StateObject private var globalErrorCenter: GlobalErrorCenter

    init(dependencyContainer: AppDependencyContainer = AppDependencyContainer()) {
        self.dependencyContainer = dependencyContainer
        _coordinator = StateObject(wrappedValue: AppCoordinator(dependencyContainer: dependencyContainer))
        _sessionViewModel = StateObject(wrappedValue: dependencyContainer.makeSessionViewModel())
        _authViewModel = StateObject(wrappedValue: dependencyContainer.makeAuthViewModel())
        _globalErrorCenter = StateObject(wrappedValue: dependencyContainer.globalErrorCenter)
    }

    var body: some View {
        Group {
            if sessionViewModel.isAuthenticated {
                authenticatedFlow
            } else {
                AuthView(viewModel: authViewModel) {
                    sessionViewModel.markAuthenticated()
                    coordinator.consumePendingRouteAfterAuthenticationIfNeeded()
                }
            }
        }
        .background(AppColors.background)
        .task {
            await sessionViewModel.restoreSessionIfNeeded()
            await dependencyContainer.refreshFeatureFlags()
            coordinator.reloadHomeDestinations()
            trackCurrentRootScreen()
        }
        .task(id: sessionViewModel.isAuthenticated) {
            guard sessionViewModel.isAuthenticated else {
                return
            }

            await dependencyContainer.preparePushNotificationsIfNeeded()
            await dependencyContainer.requestPushAuthorizationIfNeeded()
        }
        .onOpenURL { url in
            Task { @MainActor in
                let routeResult = coordinator.handleIncomingURL(
                    url,
                    isAuthenticated: sessionViewModel.isAuthenticated
                )
                if case .failed(let reason) = routeResult {
                    globalErrorCenter.present(
                        .validation(message: reason.userMessage),
                        source: "offers_deep_link"
                    )
                    return
                }

                if routeResult != .notHandled {
                    return
                }

                let didHandleAuthDeepLink = await authViewModel.consumeDeepLink(url)
                if didHandleAuthDeepLink {
                    sessionViewModel.markAuthenticated()
                    coordinator.consumePendingRouteAfterAuthenticationIfNeeded()
                }
            }
        }
        .onChange(of: sessionViewModel.isAuthenticated) { _, isAuthenticated in
            if isAuthenticated {
                coordinator.consumePendingRouteAfterAuthenticationIfNeeded()
            }
            trackCurrentRootScreen()
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active, sessionViewModel.isAuthenticated else {
                return
            }

            Task {
                _ = await dependencyContainer.refreshOffersFeedOnResumeIfNeeded()
            }
        }
        .alert(item: Binding(
            get: { globalErrorCenter.presentedError },
            set: { _ in globalErrorCenter.dismiss() }
        )) { error in
            Alert(
                title: Text("Something went wrong"),
                message: Text(error.message),
                dismissButton: .default(Text("OK")) {
                    globalErrorCenter.dismiss()
                }
            )
        }
    }

    private var authenticatedFlow: some View {
        NavigationStack(path: $coordinator.path) {
            HomeView(viewModel: coordinator.homeViewModel) { destination in
                coordinator.handleHomeAction(destination)
            }
            .navigationTitle("Home")
            .navigationDestination(for: AppRoute.self) { route in
                coordinator.destinationView(for: route)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Logout") {
                        Task {
                            await authViewModel.logout()
                            sessionViewModel.markUnauthenticated()
                            coordinator.resetNavigation()
                        }
                    }
                    .accessibilityLabel("logout_button")
                }
            }
        }
    }

    private func trackCurrentRootScreen() {
        let screenEventName = sessionViewModel.isAuthenticated
            ? ObservabilityEventName.Screen.homeViewed
            : ObservabilityEventName.Screen.authViewed

        Task {
            await dependencyContainer.analyticsTracker.track(AnalyticsEvent(name: screenEventName))
            dependencyContainer.rumMonitor.trackScreen(name: screenEventName, attributes: [:])
        }
    }
}
