#if canImport(Sentry)
import Analytics
import Foundation
@preconcurrency import Sentry

final class SentryRUMMonitor: @unchecked Sendable, RUMMonitoring {
    private let lock = NSLock()
    private var isConfigured = false

    @discardableResult
    func configureIfNeeded(_ configuration: RUMConfiguration?) -> Bool {
        lock.lock()
        defer { lock.unlock() }

        guard isConfigured == false,
              let configuration,
              configuration.dsn.isEmpty == false else {
            return isConfigured
        }

        SentrySDK.start { options in
            options.dsn = configuration.dsn
            options.environment = configuration.environment
            if let release = configuration.release, release.isEmpty == false {
                options.releaseName = release
            }
            options.enableAutoSessionTracking = true
            options.enablePerformanceTracing = true
            options.tracesSampleRate = 1.0
        }

        isConfigured = true
        return true
    }

    func trackScreen(name: String, attributes: [String: String]) {
        addBreadcrumb(category: "screen", message: name, data: attributes)
    }

    func trackAction(name: String, attributes: [String: String]) {
        addBreadcrumb(category: "action", message: name, data: attributes)
    }

    func trackLoad(name: String, durationMilliseconds: Double, attributes: [String: String]) {
        var data = attributes
        data["duration_ms"] = String(format: "%.2f", durationMilliseconds)
        addBreadcrumb(category: "load", message: name, data: data)
    }

    func trackMetric(name: String, value: Double, unit: String, tags: [String: String]) {
        var data = tags
        data["value"] = String(format: "%.4f", value)
        data["unit"] = unit
        addBreadcrumb(category: "metric", message: name, data: data)
    }

    func trackError(name: String, reason: String, attributes: [String: String]) {
        var data = attributes
        data["reason"] = reason
        addBreadcrumb(category: "error", message: name, data: data)
    }

    private func addBreadcrumb(category: String, message: String, data: [String: String]) {
        guard isConfigured else { return }

        let breadcrumb = Breadcrumb()
        breadcrumb.level = .info
        breadcrumb.category = category
        breadcrumb.message = message
        breadcrumb.data = data
        SentrySDK.addBreadcrumb(breadcrumb)
    }
}
#endif
