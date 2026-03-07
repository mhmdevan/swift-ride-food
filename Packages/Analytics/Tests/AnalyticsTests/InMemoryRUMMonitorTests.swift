import Testing
@testable import Analytics

@Test
func inMemoryRUMMonitorStoresTrackedRecords() {
    let monitor = InMemoryRUMMonitor()
    _ = monitor.configureIfNeeded(
        RUMConfiguration(
            dsn: "https://example.ingest.sentry.io/1",
            environment: "test",
            release: "1.0.0"
        )
    )

    monitor.trackScreen(name: "screen_home_viewed", attributes: ["screen": "home"])
    monitor.trackAction(name: "home_action_selected", attributes: ["destination": "catalog"])
    monitor.trackLoad(
        name: "offers_feed_load_sample",
        durationMilliseconds: 512.4,
        attributes: ["profile": "warm"]
    )
    monitor.trackMetric(
        name: "offers_feed_load_p95_ms",
        value: 780,
        unit: "ms",
        tags: ["profile": "warm"]
    )
    monitor.trackError(
        name: "offers_feed_load_failed",
        reason: "timeout",
        attributes: [:]
    )

    let records = monitor.trackedRecords()
    #expect(records.count == 5)
    #expect(records.map(\.kind) == ["screen", "action", "load", "metric", "error"])
}

@Test
func noOpRUMMonitorReturnsFalseWithoutConfiguration() {
    let monitor = NoOpRUMMonitor()
    let configured = monitor.configureIfNeeded(nil)

    #expect(configured == false)
}
