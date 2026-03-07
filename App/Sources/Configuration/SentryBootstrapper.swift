import Analytics
import Foundation

enum SentryBootstrapper {
    static func configuration(
        bundle: Bundle = .main,
        valueProvider: ((String) -> Any?)? = nil
    ) -> RUMConfiguration? {
        let infoValue = valueProvider ?? { key in
            bundle.object(forInfoDictionaryKey: key)
        }

        guard let dsn = infoValue("SENTRY_DSN") as? String,
              dsn.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false else {
            return nil
        }

        let environment = (infoValue("SENTRY_ENVIRONMENT") as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let release = (infoValue("CFBundleShortVersionString") as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedEnvironment: String
        if let environment, environment.isEmpty == false {
            resolvedEnvironment = environment
        } else {
            resolvedEnvironment = "production"
        }

        return RUMConfiguration(
            dsn: dsn,
            environment: resolvedEnvironment,
            release: release?.isEmpty == false ? release : nil
        )
    }
}
