#if canImport(FirebaseAnalytics)
import FirebaseAnalytics

public actor FirebaseAnalyticsTracker: AnalyticsTracking {
    public init() {}

    public func track(_ event: AnalyticsEvent) async {
        let parameters: [String: Any]
        if event.parameters.isEmpty {
            parameters = [:]
        } else {
            parameters = Dictionary(uniqueKeysWithValues: event.parameters.map { ($0.key, $0.value as Any) })
        }

        FirebaseAnalytics.Analytics.logEvent(
            event.name,
            parameters: parameters.isEmpty ? nil : parameters
        )
    }
}
#endif
