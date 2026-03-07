import Analytics
import FeaturesCatalogUIKit
@testable import SwiftRideFood
import XCTest

final class OffersPerformanceMonitorTests: XCTestCase {
    func testRecordFeedMeasurementTracksLoadAndMetrics() async {
        let tracker = InMemoryAnalyticsTracker()
        let rumMonitor = InMemoryRUMMonitor()
        let monitor = OffersPerformanceMonitor(tracker: tracker, rumMonitor: rumMonitor)

        await monitor.recordFeedMeasurement(
            OffersFeedLoadMeasurement(
                durationMilliseconds: 720,
                outcome: .success,
                itemCount: 8,
                isWarmStart: true,
                cacheProbe: .hit(source: .cacheFresh)
            )
        )

        let events = await tracker.trackedEvents()
        let records = rumMonitor.trackedRecords()

        XCTAssertTrue(events.contains(where: { $0.name == ObservabilityEventName.Load.offersFeedSample }))
        XCTAssertTrue(records.contains(where: { $0.kind == "load" && $0.name == ObservabilityEventName.Load.offersFeedSample }))
        XCTAssertTrue(records.contains(where: { $0.kind == "metric" && $0.name == ObservabilityEventName.Metric.offersFeedP95 }))
    }

    func testRecordPaginationMeasurementTracksErrorRateMetric() async {
        let tracker = InMemoryAnalyticsTracker()
        let rumMonitor = InMemoryRUMMonitor()
        let monitor = OffersPerformanceMonitor(tracker: tracker, rumMonitor: rumMonitor)

        await monitor.recordPaginationMeasurement(
            OffersPaginationMeasurement(
                durationMilliseconds: 320,
                outcome: .failure,
                appendedItemCount: 0
            )
        )

        let events = await tracker.trackedEvents()
        let records = rumMonitor.trackedRecords()

        XCTAssertTrue(events.contains(where: { $0.name == ObservabilityEventName.Load.offersPaginationSample }))
        XCTAssertTrue(records.contains(where: { $0.kind == "metric" && $0.name == ObservabilityEventName.Metric.offersPaginationErrorRate }))
    }
}
