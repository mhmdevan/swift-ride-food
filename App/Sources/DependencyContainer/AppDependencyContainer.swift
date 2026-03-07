import Analytics
import Core
import Data
import FeatureFlags
import FeaturesAuth
import FeaturesCatalogUIKit
import FeaturesHome
import FeaturesMap
import FeaturesOrders
import Foundation
import Networking
import PushNotifications

@MainActor
final class AppDependencyContainer {
    let analyticsTracker: any AnalyticsTracking
    let crashReporter: any CrashReporting
    let rumMonitor: any RUMMonitoring
    let tokenStore: any AuthTokenStoring
    let authRepository: any AuthRepository
    let orderRepository: any OrderRepository
    let globalErrorCenter: GlobalErrorCenter

    private let biometricAuthenticator: any BiometricAuthenticating
    private let coreDataStack: CoreDataStack
    private let liveUpdatesClient: any WebSocketClient
    private let featureFlagsService: FeatureFlagsService
    private let pushNotificationCoordinator: PushNotificationCoordinator
    private let restOffersRepository: CachedOffersRepository
    private let graphQLOffersRepository: GraphQLOffersRepository
    private let graphQLFallbackOffersRepository: FallbackOffersRepository
    private let offersFeedRefreshCoordinator: OffersFeedRefreshCoordinator
    private let offersPerformanceMonitor: OffersPerformanceMonitor
    private let offersBackgroundRefreshManager: OffersBackgroundRefreshManager
    private let trackedOrderID: UUID
    private var featureFlags: FeatureFlags

    init(
        analyticsTracker: (any AnalyticsTracking)? = nil,
        crashReporter: (any CrashReporting)? = nil,
        tokenStore: any AuthTokenStoring = KeychainTokenStore(
            service: "com.evan.swiftridefood",
            account: "auth_token"
        ),
        biometricAuthenticator: any BiometricAuthenticating = LocalBiometricAuthenticator(),
        authRepository: (any AuthRepository)? = nil,
        orderRepository: (any OrderRepository)? = nil,
        remoteConfigProvider: (any RemoteConfigProviding)? = nil,
        pushMessagingClient: (any PushMessagingClient)? = nil,
        globalErrorCenter: GlobalErrorCenter = GlobalErrorCenter(),
        pushNotificationCoordinator: PushNotificationCoordinator? = nil
    ) {
        let runtimeIntegrations = AppRuntimeIntegrations.resolve()
        let selectedAnalyticsTracker = analyticsTracker ?? runtimeIntegrations.analyticsTracker
        let selectedCrashReporter = crashReporter ?? runtimeIntegrations.crashReporter
        let selectedRUMMonitor = runtimeIntegrations.rumMonitor
        self.analyticsTracker = selectedAnalyticsTracker
        self.crashReporter = selectedCrashReporter
        rumMonitor = selectedRUMMonitor
        self.tokenStore = tokenStore
        self.biometricAuthenticator = biometricAuthenticator
        self.globalErrorCenter = globalErrorCenter
        restOffersRepository = CachedOffersRepository(remoteDataSource: RESTOffersRemoteDataSource())
        graphQLOffersRepository = GraphQLOffersRepository()
        graphQLFallbackOffersRepository = FallbackOffersRepository(
            primary: graphQLOffersRepository,
            fallback: restOffersRepository
        )
        offersFeedRefreshCoordinator = OffersFeedRefreshCoordinator(
            tracker: selectedAnalyticsTracker,
            crashReporter: selectedCrashReporter,
            rumMonitor: selectedRUMMonitor
        )
        offersPerformanceMonitor = OffersPerformanceMonitor(
            tracker: selectedAnalyticsTracker,
            rumMonitor: selectedRUMMonitor
        )
        offersBackgroundRefreshManager = OffersBackgroundRefreshManager(tracker: selectedAnalyticsTracker)
        coreDataStack = CoreDataStack()
        featureFlags = .default
        trackedOrderID = UUID(uuidString: "11111111-1111-1111-1111-111111111111") ?? UUID()
        liveUpdatesClient = MockWebSocketClient(trackedOrderID: trackedOrderID)
        let selectedRemoteConfigProvider = remoteConfigProvider ?? runtimeIntegrations.remoteConfigProvider
        featureFlagsService = FeatureFlagsService(remoteConfigProvider: selectedRemoteConfigProvider)

        if let pushNotificationCoordinator {
            self.pushNotificationCoordinator = pushNotificationCoordinator
        } else {
            let selectedPushMessagingClient = pushMessagingClient ?? runtimeIntegrations.pushMessagingClient
            self.pushNotificationCoordinator = PushNotificationCoordinator(
                pushService: PushNotificationService(messagingClient: selectedPushMessagingClient),
                tracker: self.analyticsTracker,
                crashReporter: self.crashReporter,
                globalErrorHandler: globalErrorCenter
            )
        }

        let authInterceptor = AuthTokenInterceptor { [tokenStore] in
            try? await tokenStore.readToken()
        }

        guard let baseURL = URL(string: "https://api.swiftridefood.com") else {
            preconditionFailure("Invalid API base URL.")
        }
        let networkClient = URLSessionHTTPClient(
            baseURL: baseURL,
            transport: FixtureMockHTTPTransport(),
            retryPolicy: RetryPolicy(maxAttempts: 2),
            interceptors: [authInterceptor],
            logger: ConsoleNetworkLogger()
        )

        if let authRepository {
            self.authRepository = authRepository
        } else {
            self.authRepository = NetworkAuthRepository(httpClient: networkClient)
        }

        if let orderRepository {
            self.orderRepository = orderRepository
        } else {
            let remoteOrderDataSource = NetworkOrderDataSource(httpClient: networkClient)
            let localOrderStore = CoreDataLocalOrderStore(coreDataStack: coreDataStack)
            self.orderRepository = ReadThroughOrderRepository(
                localStore: localOrderStore,
                remoteDataSource: remoteOrderDataSource
            )
        }
    }

    func refreshFeatureFlags() async {
        featureFlags = await featureFlagsService.refresh()
    }

    func availableHomeDestinations() -> [HomeDestination] {
        var destinations: [HomeDestination] = [.auth, .map, .orders]

        if featureFlags.enableNewCatalogUI {
            destinations.append(.catalog)
        }

        return destinations
    }

    func preparePushNotificationsIfNeeded() async {
        await pushNotificationCoordinator.prepareIfNeeded()
    }

    func requestPushAuthorizationIfNeeded() async {
        await pushNotificationCoordinator.requestAuthorizationIfNeeded()
    }

    func makePushNotificationCoordinator() -> PushNotificationCoordinator {
        pushNotificationCoordinator
    }

    func makeOffersBackgroundRefreshManager() -> OffersBackgroundRefreshManager {
        offersBackgroundRefreshManager
    }

    func makeSessionViewModel() -> SessionViewModel {
        SessionViewModel(tokenStore: tokenStore)
    }

    func makeHomeViewModel() -> HomeViewModel {
        HomeViewModel(actions: availableHomeDestinations(), tracker: analyticsTracker)
    }

    func makeAuthViewModel() -> AuthViewModel {
        AuthViewModel(
            authRepository: authRepository,
            tokenStore: tokenStore,
            biometricAuthenticator: biometricAuthenticator,
            tracker: analyticsTracker,
            crashReporter: crashReporter,
            globalErrorHandler: globalErrorCenter
        )
    }

    func makeMapViewModel() -> MapTrackingViewModel {
        let selectedWebSocketClient: any WebSocketClient = featureFlags.enableWebSocket
            ? liveUpdatesClient
            : DisabledWebSocketClient()

        MapTrackingViewModel(
            liveUpdatesClient: selectedWebSocketClient,
            trackedOrderID: trackedOrderID,
            tracker: analyticsTracker,
            crashReporter: crashReporter,
            globalErrorHandler: globalErrorCenter
        )
    }

    func makeOrdersViewModel() -> OrdersViewModel {
        OrdersViewModel(
            repository: orderRepository,
            tracker: analyticsTracker,
            crashReporter: crashReporter,
            globalErrorHandler: globalErrorCenter
        )
    }

    func makeOffersViewModel() -> OffersViewModel {
        let selectedRepository = selectedOffersRepository()
        let viewModel = OffersViewModel(repository: selectedRepository)
        viewModel.onFeedLoadMeasurement = { [offersPerformanceMonitor] measurement in
            Task {
                await offersPerformanceMonitor.recordFeedMeasurement(measurement)
            }
        }
        viewModel.onPaginationMeasurement = { [offersPerformanceMonitor] measurement in
            Task {
                await offersPerformanceMonitor.recordPaginationMeasurement(measurement)
            }
        }
        return viewModel
    }

    func refreshOffersFeedInBackgroundTask() async -> OffersFeedRefreshOutcome {
        let selectedRepository = selectedOffersRepository()
        return await offersFeedRefreshCoordinator.refreshIfNeeded(
            using: selectedRepository,
            reason: .backgroundTask,
            force: true
        )
    }

    func refreshOffersFeedOnResumeIfNeeded() async -> OffersFeedRefreshOutcome {
        let selectedRepository = selectedOffersRepository()
        return await offersFeedRefreshCoordinator.refreshIfNeeded(
            using: selectedRepository,
            reason: .appResume
        )
    }

    private func selectedOffersRepository() -> any OffersRepository {
        let selectedVariant: OffersBackendVariant = featureFlags.enableGraphQLOffersBackend
            ? .graphQL
            : .rest

        switch selectedVariant {
        case .rest:
            return restOffersRepository
        case .graphQL:
            return graphQLFallbackOffersRepository
        }
    }
}
