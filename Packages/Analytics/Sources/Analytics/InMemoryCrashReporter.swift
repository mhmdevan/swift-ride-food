import Foundation

public actor InMemoryCrashReporter: CrashReporting {
    public struct CapturedError: Equatable, Sendable {
        public let description: String
        public let context: [String: String]

        public init(description: String, context: [String: String]) {
            self.description = description
            self.context = context
        }
    }

    private var breadcrumbs: [CrashBreadcrumb] = []
    private var capturedErrors: [CapturedError] = []

    public init() {}

    public func addBreadcrumb(_ breadcrumb: CrashBreadcrumb) async {
        breadcrumbs.append(breadcrumb)
    }

    public func recordNonFatal(_ error: any Error, context: [String: String]) async {
        capturedErrors.append(
            CapturedError(description: String(describing: error), context: context)
        )
    }

    public func trackedBreadcrumbs() async -> [CrashBreadcrumb] {
        breadcrumbs
    }

    public func trackedErrors() async -> [CapturedError] {
        capturedErrors
    }
}
