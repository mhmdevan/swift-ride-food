import Analytics
import FeaturesCatalogUIKit
import Foundation

actor OffersPerformanceMonitor {
    private let tracker: any AnalyticsTracking
    private let rumMonitor: any RUMMonitoring

    private var warmLatencies: [Double] = []
    private var coldLatencies: [Double] = []
    private var cacheHitCount = 0
    private var cacheProbeCount = 0
    private var paginationTotalCount = 0
    private var paginationFailureCount = 0

    init(
        tracker: any AnalyticsTracking,
        rumMonitor: any RUMMonitoring
    ) {
        self.tracker = tracker
        self.rumMonitor = rumMonitor
    }

    func recordFeedMeasurement(_ measurement: OffersFeedLoadMeasurement) async {
        let profile = measurement.isWarmStart ? "warm" : "cold"
        let roundedDuration = round(measurement.durationMilliseconds)

        if measurement.isWarmStart {
            warmLatencies.append(measurement.durationMilliseconds)
        } else {
            coldLatencies.append(measurement.durationMilliseconds)
        }
        trimSamplesIfNeeded()

        switch measurement.cacheProbe {
        case .hit:
            cacheProbeCount += 1
            cacheHitCount += 1
        case .miss:
            cacheProbeCount += 1
        }

        await tracker.track(
            AnalyticsEvent(
                name: ObservabilityEventName.Load.offersFeedSample,
                parameters: [
                    "profile": profile,
                    "duration_ms": String(Int(roundedDuration)),
                    "outcome": measurement.outcome.rawValue,
                    "item_count": String(measurement.itemCount)
                ]
            )
        )

        rumMonitor.trackLoad(
            name: ObservabilityEventName.Load.offersFeedSample,
            durationMilliseconds: measurement.durationMilliseconds,
            attributes: [
                "profile": profile,
                "outcome": measurement.outcome.rawValue
            ]
        )

        let samples = measurement.isWarmStart ? warmLatencies : coldLatencies
        let p50 = percentile(50, in: samples)
        let p95 = percentile(95, in: samples)
        let cacheHitRatio = cacheProbeCount == 0
            ? 0
            : Double(cacheHitCount) / Double(cacheProbeCount)

        rumMonitor.trackMetric(
            name: ObservabilityEventName.Metric.offersFeedP50,
            value: p50,
            unit: "ms",
            tags: ["profile": profile]
        )
        rumMonitor.trackMetric(
            name: ObservabilityEventName.Metric.offersFeedP95,
            value: p95,
            unit: "ms",
            tags: ["profile": profile]
        )
        rumMonitor.trackMetric(
            name: ObservabilityEventName.Metric.offersCacheHitRatio,
            value: cacheHitRatio,
            unit: "ratio",
            tags: [:]
        )
    }

    func recordPaginationMeasurement(_ measurement: OffersPaginationMeasurement) async {
        paginationTotalCount += 1
        if measurement.outcome == .failure {
            paginationFailureCount += 1
        }

        let paginationErrorRate = paginationTotalCount == 0
            ? 0
            : Double(paginationFailureCount) / Double(paginationTotalCount)

        await tracker.track(
            AnalyticsEvent(
                name: ObservabilityEventName.Load.offersPaginationSample,
                parameters: [
                    "duration_ms": String(Int(round(measurement.durationMilliseconds))),
                    "outcome": measurement.outcome.rawValue,
                    "appended_item_count": String(measurement.appendedItemCount)
                ]
            )
        )

        rumMonitor.trackLoad(
            name: ObservabilityEventName.Load.offersPaginationSample,
            durationMilliseconds: measurement.durationMilliseconds,
            attributes: ["outcome": measurement.outcome.rawValue]
        )
        rumMonitor.trackMetric(
            name: ObservabilityEventName.Metric.offersPaginationErrorRate,
            value: paginationErrorRate,
            unit: "ratio",
            tags: [:]
        )
    }

    private func trimSamplesIfNeeded(maxCount: Int = 200) {
        if warmLatencies.count > maxCount {
            warmLatencies.removeFirst(warmLatencies.count - maxCount)
        }
        if coldLatencies.count > maxCount {
            coldLatencies.removeFirst(coldLatencies.count - maxCount)
        }
    }

    private func percentile(_ rank: Int, in samples: [Double]) -> Double {
        guard samples.isEmpty == false else { return 0 }
        let sorted = samples.sorted()
        let clampedRank = min(max(rank, 0), 100)
        let index = Int(round((Double(clampedRank) / 100.0) * Double(sorted.count - 1)))
        return sorted[index]
    }
}
