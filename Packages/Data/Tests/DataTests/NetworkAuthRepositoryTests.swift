import Core
import Foundation
import Networking
import Testing
@testable import Data

private func makeFixtureBackedHTTPClient() throws -> URLSessionHTTPClient {
    let baseURL = try #require(URL(string: "https://api.swiftridefood.com"))
    return URLSessionHTTPClient(
        baseURL: baseURL,
        transport: FixtureMockHTTPTransport(latencyNanoseconds: 0)
    )
}

@Test
func loginReturnsTokenWhenCredentialsAreValid() async throws {
    let repository = NetworkAuthRepository(httpClient: try makeFixtureBackedHTTPClient())

    let token = try await repository.login(email: "user@example.com", password: "123456")

    #expect(token == "demo-token-abc-123")
}

@Test
func loginReturnsMappedAppErrorForInvalidCredentials() async throws {
    let repository = NetworkAuthRepository(httpClient: try makeFixtureBackedHTTPClient())

    do {
        _ = try await repository.login(email: "user@example.com", password: "wrong")
        Issue.record("Expected login to fail")
    } catch let error as AppError {
        #expect(error.errorDescription == "Invalid email or password")
    }
}
