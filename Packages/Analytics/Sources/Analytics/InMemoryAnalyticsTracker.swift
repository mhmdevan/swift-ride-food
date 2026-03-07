public actor InMemoryAnalyticsTracker: AnalyticsTracking {
    private var events: [AnalyticsEvent] = []

    public init() {}

    public func track(_ event: AnalyticsEvent) async {
        events.append(event)
    }

    public func trackedEvents() async -> [AnalyticsEvent] {
        events
    }
}
