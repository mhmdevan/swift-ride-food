import Analytics
import Core
import Data
import Foundation

@MainActor
public final class AuthViewModel: ObservableObject {
    @Published public var email: String = ""
    @Published public var password: String = ""
    @Published public private(set) var state: LoadableState<Void> = .idle
    @Published public private(set) var isAuthenticated: Bool = false
    @Published public private(set) var canUseBiometrics: Bool

    private let authRepository: any AuthRepository
    private let tokenStore: any AuthTokenStoring
    private let biometricAuthenticator: any BiometricAuthenticating
    private let tracker: any AnalyticsTracking
    private let crashReporter: any CrashReporting
    private let globalErrorHandler: any GlobalErrorHandling
    private let deepLinkParser: AuthDeepLinkParser

    public init(
        authRepository: any AuthRepository,
        tokenStore: any AuthTokenStoring,
        biometricAuthenticator: any BiometricAuthenticating = DisabledBiometricAuthenticator(),
        tracker: any AnalyticsTracking = NoOpAnalyticsTracker(),
        crashReporter: any CrashReporting = NoOpCrashReporter(),
        globalErrorHandler: any GlobalErrorHandling = NoOpGlobalErrorHandler(),
        deepLinkParser: AuthDeepLinkParser = AuthDeepLinkParser()
    ) {
        self.authRepository = authRepository
        self.tokenStore = tokenStore
        self.biometricAuthenticator = biometricAuthenticator
        self.tracker = tracker
        self.crashReporter = crashReporter
        self.globalErrorHandler = globalErrorHandler
        self.deepLinkParser = deepLinkParser
        canUseBiometrics = biometricAuthenticator.canEvaluate()
    }

    public func restoreSessionIfAvailable() async {
        do {
            if let storedToken = try await tokenStore.readToken(), storedToken.isEmpty == false {
                isAuthenticated = true
                state = .loaded(())
            }
        } catch {
            state = .failed(.storage(message: "Unable to read persisted session"))
        }
    }

    public func signIn() async {
        guard email.contains("@"), password.count >= 6 else {
            state = .failed(.validation(message: "Enter a valid email and password."))
            return
        }

        state = .loading
        await crashReporter.addBreadcrumb(
            CrashBreadcrumb(
                message: "Sign in started",
                category: "auth",
                metadata: ["email_domain": email.split(separator: "@").last.map(String.init) ?? "unknown"]
            )
        )

        do {
            let token = try await authRepository.login(email: email, password: password)
            try await tokenStore.saveToken(token)
            isAuthenticated = true
            state = .loaded(())
            await tracker.track(AnalyticsEvent(name: "login_success"))
        } catch let error as AppError {
            state = .failed(error)
            await crashReporter.recordNonFatal(
                error,
                context: ["feature": "auth", "action": "sign_in"]
            )
            globalErrorHandler.present(error, source: "auth_sign_in")
        } catch {
            state = .failed(.unknown)
            await crashReporter.recordNonFatal(
                error,
                context: ["feature": "auth", "action": "sign_in_unknown"]
            )
            globalErrorHandler.present(.unknown, source: "auth_sign_in_unknown")
        }
    }

    public func unlockWithBiometrics() async {
        guard canUseBiometrics else {
            state = .failed(.validation(message: "Biometric authentication is unavailable on this device."))
            return
        }

        state = .loading

        let authorized = await biometricAuthenticator.authenticate(reason: "Unlock your SwiftRide & Food account")

        guard authorized else {
            state = .failed(.validation(message: "Biometric authentication failed."))
            return
        }

        do {
            guard let token = try await tokenStore.readToken(), token.isEmpty == false else {
                state = .failed(.validation(message: "No saved session token found."))
                return
            }

            isAuthenticated = true
            state = .loaded(())
            await tracker.track(AnalyticsEvent(name: "biometric_login_success"))
        } catch {
            state = .failed(.storage(message: "Unable to access saved session."))
            await crashReporter.recordNonFatal(
                error,
                context: ["feature": "auth", "action": "biometric_unlock"]
            )
            globalErrorHandler.present(
                .storage(message: "Unable to access saved session."),
                source: "auth_biometric_unlock"
            )
        }
    }

    @discardableResult
    public func consumeDeepLink(_ url: URL) async -> Bool {
        guard let token = deepLinkParser.token(from: url), token.isEmpty == false else {
            return false
        }

        do {
            try await tokenStore.saveToken(token)
            isAuthenticated = true
            state = .loaded(())
            await tracker.track(AnalyticsEvent(name: "deep_link_login_success"))
            return true
        } catch {
            state = .failed(.storage(message: "Unable to persist deep link token."))
            await crashReporter.recordNonFatal(
                error,
                context: ["feature": "auth", "action": "consume_deep_link"]
            )
            globalErrorHandler.present(
                .storage(message: "Unable to persist deep link token."),
                source: "auth_consume_deep_link"
            )
            return false
        }
    }

    public func logout() async {
        do {
            try await tokenStore.clearToken()
            isAuthenticated = false
            state = .idle
            email = ""
            password = ""
            await tracker.track(AnalyticsEvent(name: "logout_success"))
        } catch {
            state = .failed(.storage(message: "Unable to clear session."))
            await crashReporter.recordNonFatal(
                error,
                context: ["feature": "auth", "action": "logout"]
            )
            globalErrorHandler.present(
                .storage(message: "Unable to clear session."),
                source: "auth_logout"
            )
        }
    }
}
