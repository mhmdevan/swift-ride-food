public struct NoOpRUMMonitor: RUMMonitoring {
    public init() {}

    public func configureIfNeeded(_ configuration: RUMConfiguration?) -> Bool {
        _ = configuration
        return false
    }

    public func trackScreen(name: String, attributes: [String: String]) {
        _ = name
        _ = attributes
    }

    public func trackAction(name: String, attributes: [String: String]) {
        _ = name
        _ = attributes
    }

    public func trackLoad(name: String, durationMilliseconds: Double, attributes: [String: String]) {
        _ = name
        _ = durationMilliseconds
        _ = attributes
    }

    public func trackMetric(name: String, value: Double, unit: String, tags: [String: String]) {
        _ = name
        _ = value
        _ = unit
        _ = tags
    }

    public func trackError(name: String, reason: String, attributes: [String: String]) {
        _ = name
        _ = reason
        _ = attributes
    }
}
