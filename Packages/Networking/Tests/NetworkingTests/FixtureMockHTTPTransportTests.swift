import Foundation
import Testing
@testable import Networking

private func makeRequest(url: URL, method: HTTPMethod, body: Data? = nil) -> URLRequest {
    var request = URLRequest(url: url)
    request.httpMethod = method.rawValue
    request.httpBody = body
    return request
}

@Test
func fixtureTransportReturnsLoginSuccessForValidCredentials() async throws {
    let url = try #require(URL(string: "https://api.swiftridefood.com/login"))
    let body = Data("{\"email\":\"user@example.com\",\"password\":\"123456\"}".utf8)
    let request = makeRequest(url: url, method: .post, body: body)

    let transport = FixtureMockHTTPTransport(latencyNanoseconds: 0)
    let (data, response) = try await transport.data(for: request)

    let httpResponse = try #require(response as? HTTPURLResponse)
    #expect(httpResponse.statusCode == 200)
    #expect(String(data: data, encoding: .utf8)?.contains("demo-token") == true)
}

@Test
func fixtureTransportReturnsOrderDetailsForKnownIdentifier() async throws {
    let url = try #require(URL(string: "https://api.swiftridefood.com/orders/11111111-1111-1111-1111-111111111111"))
    let request = makeRequest(url: url, method: .get)

    let transport = FixtureMockHTTPTransport(latencyNanoseconds: 0)
    let (data, response) = try await transport.data(for: request)

    let httpResponse = try #require(response as? HTTPURLResponse)
    #expect(httpResponse.statusCode == 200)
    #expect(String(data: data, encoding: .utf8)?.contains("Food Delivery #1001") == true)
}

@Test
func fixtureTransportReturnsNotFoundForUnknownPath() async throws {
    let url = try #require(URL(string: "https://api.swiftridefood.com/unknown"))
    let request = makeRequest(url: url, method: .get)

    let transport = FixtureMockHTTPTransport(latencyNanoseconds: 0)
    let (data, response) = try await transport.data(for: request)

    let httpResponse = try #require(response as? HTTPURLResponse)
    #expect(httpResponse.statusCode == 404)
    #expect(String(data: data, encoding: .utf8)?.contains("not_found") == true)
}
