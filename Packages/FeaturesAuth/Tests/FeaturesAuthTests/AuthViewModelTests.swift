import Analytics
import Core
import Data
import Foundation
import Testing
@testable import FeaturesAuth

private actor MockAuthRepository: AuthRepository {
    enum MockError: Error {
        case loginFailed
    }

    private let result: Result<String, Error>

    init(result: Result<String, Error>) {
        self.result = result
    }

    func login(email: String, password: String) async throws -> String {
        _ = email
        _ = password
        return try result.get()
    }
}

private struct MockBiometricAuthenticator: BiometricAuthenticating {
    let canEvaluateResult: Bool
    let authenticateResult: Bool

    func canEvaluate() -> Bool {
        canEvaluateResult
    }

    func authenticate(reason: String) async -> Bool {
        _ = reason
        return authenticateResult
    }
}

@MainActor
@Test
func signInFailsForInvalidCredentials() async {
    let repository = MockAuthRepository(result: .success("token"))
    let tokenStore = InMemoryAuthTokenStore()
    let viewModel = AuthViewModel(
        authRepository: repository,
        tokenStore: tokenStore,
        biometricAuthenticator: MockBiometricAuthenticator(canEvaluateResult: false, authenticateResult: false)
    )

    viewModel.email = "invalid"
    viewModel.password = "123"

    await viewModel.signIn()

    if case .failed = viewModel.state {
        return
    }

    Issue.record("Expected failed state for invalid credentials")
}

@MainActor
@Test
func signInSucceedsForValidCredentialsAndPersistsToken() async throws {
    let repository = MockAuthRepository(result: .success("token-123"))
    let tokenStore = InMemoryAuthTokenStore()
    let tracker = InMemoryAnalyticsTracker()
    let viewModel = AuthViewModel(
        authRepository: repository,
        tokenStore: tokenStore,
        biometricAuthenticator: MockBiometricAuthenticator(canEvaluateResult: false, authenticateResult: false),
        tracker: tracker
    )

    viewModel.email = "user@example.com"
    viewModel.password = "123456"

    await viewModel.signIn()

    if case .loaded = viewModel.state {
        let events = await tracker.trackedEvents()
        #expect(viewModel.isAuthenticated)
        #expect(try await tokenStore.readToken() == "token-123")
        #expect(events.contains(where: { $0.name == "login_success" }))
        return
    }

    Issue.record("Expected loaded state for valid credentials")
}

@MainActor
@Test
func unlockWithBiometricsSucceedsWhenStoredTokenExists() async throws {
    let repository = MockAuthRepository(result: .success("unused"))
    let tokenStore = InMemoryAuthTokenStore(token: "persisted-token")
    let viewModel = AuthViewModel(
        authRepository: repository,
        tokenStore: tokenStore,
        biometricAuthenticator: MockBiometricAuthenticator(canEvaluateResult: true, authenticateResult: true)
    )

    await viewModel.unlockWithBiometrics()

    if case .loaded = viewModel.state {
        #expect(viewModel.isAuthenticated)
        return
    }

    Issue.record("Expected biometric unlock to load session")
}

@MainActor
@Test
func consumeDeepLinkPersistsTokenAndAuthenticates() async throws {
    let repository = MockAuthRepository(result: .success("unused"))
    let tokenStore = InMemoryAuthTokenStore()
    let viewModel = AuthViewModel(
        authRepository: repository,
        tokenStore: tokenStore,
        biometricAuthenticator: MockBiometricAuthenticator(canEvaluateResult: false, authenticateResult: false)
    )

    let deepLink = try #require(URL(string: "myapp://login?token=from-link"))

    let handled = await viewModel.consumeDeepLink(deepLink)

    #expect(handled)
    #expect(viewModel.isAuthenticated)
    #expect(try await tokenStore.readToken() == "from-link")
}

@MainActor
@Test
func logoutClearsSessionStateAndToken() async throws {
    let repository = MockAuthRepository(result: .success("unused"))
    let tokenStore = InMemoryAuthTokenStore(token: "persisted-token")
    let viewModel = AuthViewModel(
        authRepository: repository,
        tokenStore: tokenStore,
        biometricAuthenticator: MockBiometricAuthenticator(canEvaluateResult: false, authenticateResult: false)
    )

    await viewModel.restoreSessionIfAvailable()
    await viewModel.logout()

    #expect(viewModel.isAuthenticated == false)
    #expect(try await tokenStore.readToken() == nil)
}

@MainActor
@Test
func signInMapsRepositoryErrorToFailedState() async {
    let repository = MockAuthRepository(result: .failure(AppError.network(message: "Service unavailable")))
    let tokenStore = InMemoryAuthTokenStore()
    let viewModel = AuthViewModel(
        authRepository: repository,
        tokenStore: tokenStore,
        biometricAuthenticator: MockBiometricAuthenticator(canEvaluateResult: false, authenticateResult: false)
    )

    viewModel.email = "user@example.com"
    viewModel.password = "123456"

    await viewModel.signIn()

    if case .failed(let error) = viewModel.state {
        #expect(error.errorDescription == "Service unavailable")
        return
    }

    Issue.record("Expected failed state when repository throws")
}
