#if canImport(Foundation)
import Foundation
#endif
#if canImport(FirebaseCore)
import FirebaseCore
#endif

enum FirebaseBootstrapper {
    static func configureIfNeeded(
        bundle: Bundle = .main,
        hasConfigurationFile: (() -> Bool)? = nil,
        isAlreadyConfigured: () -> Bool = defaultIsAlreadyConfigured,
        configure: () -> Void = defaultConfigure
    ) -> Bool {
        if isAlreadyConfigured() {
            return true
        }

        let containsConfigurationFile: Bool
        if let hasConfigurationFile {
            containsConfigurationFile = hasConfigurationFile()
        } else {
            containsConfigurationFile = bundle.path(forResource: "GoogleService-Info", ofType: "plist") != nil
        }

        guard containsConfigurationFile else {
            return false
        }

        configure()
        return isAlreadyConfigured()
    }

    private static func defaultIsAlreadyConfigured() -> Bool {
#if canImport(FirebaseCore)
        FirebaseApp.app() != nil
#else
        false
#endif
    }

    private static func defaultConfigure() {
#if canImport(FirebaseCore)
        FirebaseApp.configure()
#endif
    }
}
