import Foundation

public struct RUMConfiguration: Equatable, Sendable {
    public let dsn: String
    public let environment: String
    public let release: String?

    public init(dsn: String, environment: String, release: String?) {
        self.dsn = dsn
        self.environment = environment
        self.release = release
    }
}

public protocol RUMMonitoring: Sendable {
    @discardableResult
    func configureIfNeeded(_ configuration: RUMConfiguration?) -> Bool
    func trackScreen(name: String, attributes: [String: String])
    func trackAction(name: String, attributes: [String: String])
    func trackLoad(name: String, durationMilliseconds: Double, attributes: [String: String])
    func trackMetric(name: String, value: Double, unit: String, tags: [String: String])
    func trackError(name: String, reason: String, attributes: [String: String])
}
