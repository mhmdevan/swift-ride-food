import Analytics
import Foundation

#if canImport(BackgroundTasks)
import BackgroundTasks
#endif

protocol AppRefreshScheduling {
    func submitAppRefresh(identifier: String, earliestBeginDate: Date?) throws
}

struct LiveAppRefreshScheduler: AppRefreshScheduling {
    func submitAppRefresh(identifier: String, earliestBeginDate: Date?) throws {
#if canImport(BackgroundTasks)
        let request = BGAppRefreshTaskRequest(identifier: identifier)
        request.earliestBeginDate = earliestBeginDate
        try BGTaskScheduler.shared.submit(request)
#else
        _ = identifier
        _ = earliestBeginDate
#endif
    }
}

final class OffersBackgroundRefreshManager {
    static let taskIdentifier = "com.evan.swiftridefood.offers.refresh"

    private let scheduler: any AppRefreshScheduling
    private let tracker: any AnalyticsTracking
    private let baseInterval: TimeInterval
    private let maxBackoffInterval: TimeInterval
    private let now: @Sendable () -> Date
    private var consecutiveFailureCount = 0

    init(
        scheduler: any AppRefreshScheduling = LiveAppRefreshScheduler(),
        tracker: any AnalyticsTracking,
        interval: TimeInterval = 20 * 60,
        maxBackoffInterval: TimeInterval = 2 * 60 * 60,
        now: @escaping @Sendable () -> Date = Date.init
    ) {
        self.scheduler = scheduler
        self.tracker = tracker
        baseInterval = max(60, interval)
        self.maxBackoffInterval = max(baseInterval, maxBackoffInterval)
        self.now = now
    }

    @discardableResult
    func scheduleNextRefresh(after outcome: OffersFeedRefreshOutcome? = nil) async -> Bool {
        updateBackoffState(after: outcome)
        let effectiveInterval = effectiveIntervalWithBackoff()

        do {
            let earliest = now().addingTimeInterval(effectiveInterval)
            try scheduler.submitAppRefresh(
                identifier: Self.taskIdentifier,
                earliestBeginDate: earliest
            )

            await tracker.track(
                AnalyticsEvent(
                    name: ObservabilityEventName.BackgroundRefresh.scheduled,
                    parameters: [
                        "earliest_begin_epoch": String(Int(earliest.timeIntervalSince1970)),
                        "backoff_level": String(consecutiveFailureCount),
                        "interval_seconds": String(Int(effectiveInterval))
                    ]
                )
            )
            return true
        } catch {
            await tracker.track(
                AnalyticsEvent(
                    name: ObservabilityEventName.BackgroundRefresh.scheduleFailed,
                    parameters: ["backoff_level": String(consecutiveFailureCount)]
                )
            )
            return false
        }
    }

    private func updateBackoffState(after outcome: OffersFeedRefreshOutcome?) {
        guard let outcome else { return }

        switch outcome {
        case .failed:
            consecutiveFailureCount = min(consecutiveFailureCount + 1, 8)
        case .refreshed:
            consecutiveFailureCount = 0
        case .skipped:
            break
        }
    }

    private func effectiveIntervalWithBackoff() -> TimeInterval {
        let multiplier = pow(2.0, Double(consecutiveFailureCount))
        return min(maxBackoffInterval, baseInterval * multiplier)
    }
}
