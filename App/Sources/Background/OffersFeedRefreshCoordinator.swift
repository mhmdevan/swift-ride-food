import Analytics
import FeaturesCatalogUIKit
import Foundation

enum OffersFeedRefreshReason: String, Sendable {
    case appResume
    case backgroundTask
}

enum OffersFeedRefreshOutcome: Equatable, Sendable {
    case refreshed
    case skipped
    case failed
}

struct OffersRefreshRetryPolicy: Equatable, Sendable {
    let maxAttempts: Int
    let baseDelay: TimeInterval
    let maxDelay: TimeInterval

    init(
        maxAttempts: Int = 3,
        baseDelay: TimeInterval = 1.5,
        maxDelay: TimeInterval = 12
    ) {
        self.maxAttempts = max(1, maxAttempts)
        self.baseDelay = max(0, baseDelay)
        self.maxDelay = max(baseDelay, maxDelay)
    }

    func delayNanoseconds(forRetryAttempt retryAttempt: Int) -> UInt64 {
        guard baseDelay > 0 else { return 0 }
        let multiplier = pow(2.0, Double(max(0, retryAttempt - 1)))
        let delay = min(maxDelay, baseDelay * multiplier)
        return UInt64(delay * 1_000_000_000)
    }
}

actor OffersFeedRefreshCoordinator {
    private let tracker: any AnalyticsTracking
    private let crashReporter: any CrashReporting
    private let rumMonitor: any RUMMonitoring
    private let minimumInterval: TimeInterval
    private let pageLimit: Int
    private let retryPolicy: OffersRefreshRetryPolicy
    private let sleep: @Sendable (UInt64) async -> Void
    private let now: @Sendable () -> Date

    private var inFlightTask: Task<OffersFeedRefreshOutcome, Never>?
    private var lastSuccessfulRefreshAt: Date?

    private struct RefreshAttemptContext: Sendable {
        let reason: OffersFeedRefreshReason
        let tracker: any AnalyticsTracking
        let crashReporter: any CrashReporting
        let rumMonitor: any RUMMonitoring
        let sleep: @Sendable (UInt64) async -> Void
    }

    init(
        tracker: any AnalyticsTracking,
        crashReporter: any CrashReporting,
        rumMonitor: any RUMMonitoring = NoOpRUMMonitor(),
        minimumInterval: TimeInterval = 15 * 60,
        pageLimit: Int = 8,
        retryPolicy: OffersRefreshRetryPolicy = OffersRefreshRetryPolicy(),
        sleep: @escaping @Sendable (UInt64) async -> Void = { nanoseconds in
            try? await Task.sleep(nanoseconds: nanoseconds)
        },
        now: @escaping @Sendable () -> Date = Date.init
    ) {
        self.tracker = tracker
        self.crashReporter = crashReporter
        self.rumMonitor = rumMonitor
        self.minimumInterval = max(1, minimumInterval)
        self.pageLimit = max(1, pageLimit)
        self.retryPolicy = retryPolicy
        self.sleep = sleep
        self.now = now
    }

    func refreshIfNeeded(
        using repository: any OffersRepository,
        reason: OffersFeedRefreshReason,
        force: Bool = false
    ) async -> OffersFeedRefreshOutcome {
        if let inFlightTask {
            await tracker.track(
                AnalyticsEvent(
                    name: ObservabilityEventName.BackgroundRefresh.deduplicated,
                    parameters: ["reason": reason.rawValue]
                )
            )
            rumMonitor.trackAction(
                name: ObservabilityEventName.BackgroundRefresh.deduplicated,
                attributes: ["reason": reason.rawValue]
            )
            return await inFlightTask.value
        }

        if force == false,
           let lastSuccessfulRefreshAt,
           now().timeIntervalSince(lastSuccessfulRefreshAt) < minimumInterval {
            await tracker.track(
                AnalyticsEvent(
                    name: ObservabilityEventName.BackgroundRefresh.skipped,
                    parameters: ["reason": reason.rawValue]
                )
            )
            rumMonitor.trackAction(
                name: ObservabilityEventName.BackgroundRefresh.skipped,
                attributes: ["reason": reason.rawValue]
            )
            return .skipped
        }

        let rumMonitor = self.rumMonitor
        let requestTask = Task<OffersFeedRefreshOutcome, Never> { [tracker, crashReporter, pageLimit, rumMonitor, retryPolicy, sleep] in
            let startedAt = Date()
            await crashReporter.addBreadcrumb(
                CrashBreadcrumb(
                    message: "Offers feed refresh started",
                    category: "offers_refresh",
                    metadata: ["reason": reason.rawValue]
                )
            )
            await tracker.track(
                AnalyticsEvent(
                    name: ObservabilityEventName.BackgroundRefresh.started,
                    parameters: ["reason": reason.rawValue]
                )
            )

            let context = RefreshAttemptContext(
                reason: reason,
                tracker: tracker,
                crashReporter: crashReporter,
                rumMonitor: rumMonitor,
                sleep: sleep
            )
            let fetchResult = await Self.fetchFirstPageWithRetry(
                repository: repository,
                pageLimit: pageLimit,
                retryPolicy: retryPolicy,
                context: context
            )

            switch fetchResult {
            case .success:
                await tracker.track(
                    AnalyticsEvent(
                        name: ObservabilityEventName.BackgroundRefresh.succeeded,
                        parameters: ["reason": reason.rawValue]
                    )
                )
                let elapsedMs = Date().timeIntervalSince(startedAt) * 1000
                rumMonitor.trackLoad(
                    name: ObservabilityEventName.BackgroundRefresh.succeeded,
                    durationMilliseconds: elapsedMs,
                    attributes: ["reason": reason.rawValue]
                )
                await crashReporter.addBreadcrumb(
                    CrashBreadcrumb(
                        message: "Offers feed refresh succeeded",
                        category: "offers_refresh",
                        metadata: [
                            "reason": reason.rawValue,
                            "duration_ms": String(Int(round(elapsedMs)))
                        ]
                    )
                )
                return .refreshed
            case .failure(let error):
                await crashReporter.recordNonFatal(
                    error,
                    context: ["feature": "offers_feed_refresh", "reason": reason.rawValue]
                )
                await tracker.track(
                    AnalyticsEvent(
                        name: ObservabilityEventName.BackgroundRefresh.failed,
                        parameters: ["reason": reason.rawValue]
                    )
                )
                rumMonitor.trackError(
                    name: ObservabilityEventName.BackgroundRefresh.failed,
                    reason: String(describing: error),
                    attributes: ["reason": reason.rawValue]
                )
                return .failed
            }
        }

        inFlightTask = requestTask
        let result = await requestTask.value
        inFlightTask = nil

        if result == .refreshed {
            lastSuccessfulRefreshAt = now()
        }

        return result
    }

    private static func fetchFirstPageWithRetry(
        repository: any OffersRepository,
        pageLimit: Int,
        retryPolicy: OffersRefreshRetryPolicy,
        context: RefreshAttemptContext
    ) async -> Result<Void, Error> {
        let allowsRetry = context.reason == .backgroundTask
        var currentAttempt = 1

        while true {
            do {
                _ = try await repository.fetchFirstPage(limit: pageLimit)
                return .success(())
            } catch {
                guard allowsRetry,
                      currentAttempt < retryPolicy.maxAttempts else {
                    return .failure(error)
                }

                let nextAttempt = currentAttempt + 1
                let backoffNanoseconds = retryPolicy.delayNanoseconds(forRetryAttempt: currentAttempt)
                let backoffMilliseconds = Int(backoffNanoseconds / 1_000_000)

                await context.tracker.track(
                    AnalyticsEvent(
                        name: ObservabilityEventName.Retry.offersFeedRetry,
                        parameters: [
                            "reason": context.reason.rawValue,
                            "attempt": String(nextAttempt),
                            "backoff_ms": String(backoffMilliseconds)
                        ]
                    )
                )
                await context.crashReporter.addBreadcrumb(
                    CrashBreadcrumb(
                        message: "Offers feed refresh retry scheduled",
                        category: "offers_refresh",
                        metadata: [
                            "reason": context.reason.rawValue,
                            "attempt": String(nextAttempt),
                            "backoff_ms": String(backoffMilliseconds)
                        ]
                    )
                )
                context.rumMonitor.trackAction(
                    name: ObservabilityEventName.Retry.offersFeedRetry,
                    attributes: [
                        "reason": context.reason.rawValue,
                        "attempt": String(nextAttempt),
                        "backoff_ms": String(backoffMilliseconds)
                    ]
                )

                if backoffNanoseconds > 0 {
                    await context.sleep(backoffNanoseconds)
                }
                currentAttempt = nextAttempt
            }
        }
    }
}
