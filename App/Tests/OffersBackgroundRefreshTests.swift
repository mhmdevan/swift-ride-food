import Analytics
import FeaturesCatalogUIKit
import Foundation
@testable import SwiftRideFood
import XCTest

private enum StubRepositoryError: Error {
    case failed
}

private actor StubOffersRepository: OffersRepository {
    var shouldFail = false
    var failureSequence: [Bool] = []
    var latencyNanoseconds: UInt64 = 0
    private(set) var fetchFirstPageCallCount: Int = 0

    func cachedFirstPage(limit: Int) async -> OffersPage? {
        _ = limit
        return nil
    }

    func fetchFirstPage(limit: Int) async throws -> OffersPage {
        _ = limit
        fetchFirstPageCallCount += 1

        if latencyNanoseconds > 0 {
            try await Task.sleep(nanoseconds: latencyNanoseconds)
        }
        if failureSequence.isEmpty == false {
            let shouldFailThisAttempt = failureSequence.removeFirst()
            if shouldFailThisAttempt {
                throw StubRepositoryError.failed
            }
        }
        if shouldFail {
            throw StubRepositoryError.failed
        }

        return OffersPage(items: [], nextCursor: nil, source: .network)
    }

    func fetchNextPage(after cursor: String, limit: Int) async throws -> OffersPage {
        _ = cursor
        _ = limit
        return OffersPage(items: [], nextCursor: nil, source: .network)
    }
}

private final class MockRefreshScheduler: AppRefreshScheduling {
    var shouldThrow = false
    private(set) var submissions: [(identifier: String, earliestBeginDate: Date?)] = []

    func submitAppRefresh(identifier: String, earliestBeginDate: Date?) throws {
        if shouldThrow {
            throw NSError(domain: "scheduler", code: 1)
        }

        submissions.append((identifier: identifier, earliestBeginDate: earliestBeginDate))
    }
}

final class OffersBackgroundRefreshTests: XCTestCase {
    func testRefreshCoordinatorReturnsRefreshedWhenFetchSucceeds() async {
        let tracker = InMemoryAnalyticsTracker()
        let crashReporter = InMemoryCrashReporter()
        let repository = StubOffersRepository()
        let coordinator = OffersFeedRefreshCoordinator(
            tracker: tracker,
            crashReporter: crashReporter,
            minimumInterval: 60
        )

        let outcome = await coordinator.refreshIfNeeded(
            using: repository,
            reason: .backgroundTask,
            force: true
        )

        XCTAssertEqual(outcome, .refreshed)
        XCTAssertEqual(await repository.fetchFirstPageCallCount, 1)
    }

    func testRefreshCoordinatorSkipsWhenWithinMinimumInterval() async {
        let tracker = InMemoryAnalyticsTracker()
        let crashReporter = InMemoryCrashReporter()
        let repository = StubOffersRepository()
        let now = Date(timeIntervalSince1970: 1_000)
        let coordinator = OffersFeedRefreshCoordinator(
            tracker: tracker,
            crashReporter: crashReporter,
            minimumInterval: 60,
            now: { now }
        )

        _ = await coordinator.refreshIfNeeded(using: repository, reason: .appResume, force: true)
        let second = await coordinator.refreshIfNeeded(using: repository, reason: .appResume, force: false)

        XCTAssertEqual(second, .skipped)
        XCTAssertEqual(await repository.fetchFirstPageCallCount, 1)
    }

    func testRefreshCoordinatorDeduplicatesConcurrentRequests() async {
        let tracker = InMemoryAnalyticsTracker()
        let crashReporter = InMemoryCrashReporter()
        let repository = StubOffersRepository()
        await setLatency(on: repository, nanoseconds: 50_000_000)
        let coordinator = OffersFeedRefreshCoordinator(
            tracker: tracker,
            crashReporter: crashReporter,
            minimumInterval: 60
        )

        async let first = coordinator.refreshIfNeeded(using: repository, reason: .backgroundTask, force: true)
        async let second = coordinator.refreshIfNeeded(using: repository, reason: .backgroundTask, force: true)
        let firstOutcome = await first
        let secondOutcome = await second

        XCTAssertEqual([firstOutcome, secondOutcome], [.refreshed, .refreshed])
        XCTAssertEqual(await repository.fetchFirstPageCallCount, 1)
    }

    func testRefreshCoordinatorRetriesBackgroundTaskFailuresWithBackoff() async {
        let tracker = InMemoryAnalyticsTracker()
        let crashReporter = InMemoryCrashReporter()
        let repository = StubOffersRepository()
        await repository.setFailureSequence([true, true, false])
        let observedSleeps = LockIsolated<[UInt64]>([])
        let coordinator = OffersFeedRefreshCoordinator(
            tracker: tracker,
            crashReporter: crashReporter,
            minimumInterval: 60,
            retryPolicy: OffersRefreshRetryPolicy(maxAttempts: 3, baseDelay: 0.001, maxDelay: 0.01),
            sleep: { nanoseconds in
                observedSleeps.withValue { values in
                    values.append(nanoseconds)
                }
            }
        )

        let outcome = await coordinator.refreshIfNeeded(
            using: repository,
            reason: .backgroundTask,
            force: true
        )

        let trackedEvents = await tracker.trackedEvents()
        let retryEvents = trackedEvents.filter { $0.name == ObservabilityEventName.Retry.offersFeedRetry }

        XCTAssertEqual(outcome, .refreshed)
        XCTAssertEqual(await repository.fetchFirstPageCallCount, 3)
        XCTAssertEqual(retryEvents.count, 2)
        XCTAssertEqual(observedSleeps.value.count, 2)
    }

    func testRefreshManagerSchedulesRequest() async {
        let tracker = InMemoryAnalyticsTracker()
        let scheduler = MockRefreshScheduler()
        let fixedNow = Date(timeIntervalSince1970: 2_000)
        let manager = OffersBackgroundRefreshManager(
            scheduler: scheduler,
            tracker: tracker,
            interval: 120,
            now: { fixedNow }
        )

        let didSchedule = await manager.scheduleNextRefresh(after: nil)

        XCTAssertTrue(didSchedule)
        XCTAssertEqual(scheduler.submissions.count, 1)
        XCTAssertEqual(
            scheduler.submissions.first?.identifier,
            OffersBackgroundRefreshManager.taskIdentifier
        )
        XCTAssertEqual(
            scheduler.submissions.first?.earliestBeginDate?.timeIntervalSince1970,
            fixedNow.addingTimeInterval(120).timeIntervalSince1970
        )
    }

    func testRefreshManagerReturnsFalseWhenSchedulingFails() async {
        let tracker = InMemoryAnalyticsTracker()
        let scheduler = MockRefreshScheduler()
        scheduler.shouldThrow = true
        let manager = OffersBackgroundRefreshManager(
            scheduler: scheduler,
            tracker: tracker
        )

        let didSchedule = await manager.scheduleNextRefresh(after: nil)

        XCTAssertFalse(didSchedule)
    }

    func testRefreshManagerAppliesBackoffOnFailuresAndResetsOnSuccess() async {
        let tracker = InMemoryAnalyticsTracker()
        let scheduler = MockRefreshScheduler()
        let fixedNow = Date(timeIntervalSince1970: 5_000)
        let manager = OffersBackgroundRefreshManager(
            scheduler: scheduler,
            tracker: tracker,
            interval: 60,
            maxBackoffInterval: 300,
            now: { fixedNow }
        )

        _ = await manager.scheduleNextRefresh(after: .failed)
        _ = await manager.scheduleNextRefresh(after: .failed)
        _ = await manager.scheduleNextRefresh(after: .refreshed)

        XCTAssertEqual(scheduler.submissions.count, 3)
        XCTAssertEqual(
            scheduler.submissions[0].earliestBeginDate?.timeIntervalSince1970,
            fixedNow.addingTimeInterval(120).timeIntervalSince1970
        )
        XCTAssertEqual(
            scheduler.submissions[1].earliestBeginDate?.timeIntervalSince1970,
            fixedNow.addingTimeInterval(240).timeIntervalSince1970
        )
        XCTAssertEqual(
            scheduler.submissions[2].earliestBeginDate?.timeIntervalSince1970,
            fixedNow.addingTimeInterval(60).timeIntervalSince1970
        )
    }

    private func setLatency(on repository: StubOffersRepository, nanoseconds: UInt64) async {
        await repository.setLatency(nanoseconds: nanoseconds)
    }
}

private extension StubOffersRepository {
    func setLatency(nanoseconds: UInt64) {
        latencyNanoseconds = nanoseconds
    }

    func setFailureSequence(_ sequence: [Bool]) {
        failureSequence = sequence
    }
}

private final class LockIsolated<Value>: @unchecked Sendable {
    private let lock = NSLock()
    private var _value: Value

    init(_ value: Value) {
        _value = value
    }

    func withValue(_ mutate: (inout Value) -> Void) {
        lock.lock()
        defer { lock.unlock() }
        mutate(&_value)
    }

    var value: Value {
        lock.lock()
        defer { lock.unlock() }
        return _value
    }
}
