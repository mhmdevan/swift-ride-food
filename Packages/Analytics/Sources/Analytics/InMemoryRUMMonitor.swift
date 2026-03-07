import Foundation

public final class InMemoryRUMMonitor: @unchecked Sendable, RUMMonitoring {
    public struct TrackedRecord: Equatable, Sendable {
        public let kind: String
        public let name: String
        public let attributes: [String: String]

        public init(kind: String, name: String, attributes: [String: String]) {
            self.kind = kind
            self.name = name
            self.attributes = attributes
        }
    }

    private let lock = NSLock()
    private(set) var configuredWith: RUMConfiguration?
    private var records: [TrackedRecord] = []

    public init() {}

    @discardableResult
    public func configureIfNeeded(_ configuration: RUMConfiguration?) -> Bool {
        lock.lock()
        defer { lock.unlock() }

        guard let configuration, configuration.dsn.isEmpty == false else {
            return false
        }

        configuredWith = configuration
        return true
    }

    public func trackScreen(name: String, attributes: [String: String]) {
        append(kind: "screen", name: name, attributes: attributes)
    }

    public func trackAction(name: String, attributes: [String: String]) {
        append(kind: "action", name: name, attributes: attributes)
    }

    public func trackLoad(name: String, durationMilliseconds: Double, attributes: [String: String]) {
        var payload = attributes
        payload["duration_ms"] = String(format: "%.2f", durationMilliseconds)
        append(kind: "load", name: name, attributes: payload)
    }

    public func trackMetric(name: String, value: Double, unit: String, tags: [String: String]) {
        var payload = tags
        payload["value"] = String(format: "%.4f", value)
        payload["unit"] = unit
        append(kind: "metric", name: name, attributes: payload)
    }

    public func trackError(name: String, reason: String, attributes: [String: String]) {
        var payload = attributes
        payload["reason"] = reason
        append(kind: "error", name: name, attributes: payload)
    }

    public func trackedRecords() -> [TrackedRecord] {
        lock.lock()
        defer { lock.unlock() }
        return records
    }

    private func append(kind: String, name: String, attributes: [String: String]) {
        lock.lock()
        records.append(TrackedRecord(kind: kind, name: name, attributes: attributes))
        lock.unlock()
    }
}
