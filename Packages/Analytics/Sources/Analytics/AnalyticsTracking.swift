public protocol AnalyticsTracking: Sendable {
    func track(_ event: AnalyticsEvent) async
}
