import Foundation
import Testing
@testable import Networking

@Test
func adaptAddsAuthorizationHeaderWhenTokenExists() async throws {
    let interceptor = AuthTokenInterceptor(tokenProvider: { "abc123" })
    let request = URLRequest(url: try #require(URL(string: "https://api.example.com/orders")))

    let adaptedRequest = try await interceptor.adapt(request)

    #expect(adaptedRequest.value(forHTTPHeaderField: "Authorization") == "Bearer abc123")
}

@Test
func adaptKeepsRequestUnchangedWhenTokenMissing() async throws {
    let interceptor = AuthTokenInterceptor(tokenProvider: { nil })
    let request = URLRequest(url: try #require(URL(string: "https://api.example.com/orders")))

    let adaptedRequest = try await interceptor.adapt(request)

    #expect(adaptedRequest.value(forHTTPHeaderField: "Authorization") == nil)
}
