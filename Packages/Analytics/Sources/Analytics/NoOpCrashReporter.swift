public struct NoOpCrashReporter: CrashReporting {
    public init() {}

    public func addBreadcrumb(_ breadcrumb: CrashBreadcrumb) async {
        _ = breadcrumb
    }

    public func recordNonFatal(_ error: any Error, context: [String: String]) async {
        _ = error
        _ = context
    }
}
