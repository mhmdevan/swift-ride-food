#if canImport(FirebaseCrashlytics)
import FirebaseCrashlytics

public actor FirebaseCrashReporter: CrashReporting {
    public init() {}

    public func addBreadcrumb(_ breadcrumb: CrashBreadcrumb) async {
        let metadataText = breadcrumb.metadata
            .sorted(by: { $0.key < $1.key })
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: ",")

        let message: String
        if metadataText.isEmpty {
            message = "[\(breadcrumb.category)] \(breadcrumb.message)"
        } else {
            message = "[\(breadcrumb.category)] \(breadcrumb.message) {\(metadataText)}"
        }

        Crashlytics.crashlytics().log(message)
    }

    public func recordNonFatal(_ error: any Error, context: [String: String]) async {
        for (key, value) in context {
            Crashlytics.crashlytics().setCustomValue(value, forKey: key)
        }

        Crashlytics.crashlytics().record(error: error)
    }
}
#endif
