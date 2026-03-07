public protocol CrashReporting: Sendable {
    func addBreadcrumb(_ breadcrumb: CrashBreadcrumb) async
    func recordNonFatal(_ error: any Error, context: [String: String]) async
}
