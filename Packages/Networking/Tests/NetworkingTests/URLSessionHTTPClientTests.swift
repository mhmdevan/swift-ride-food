import Foundation
import Testing
import Core
@testable import Networking

private actor MockNetworkTransport: NetworkTransport {
    private var queue: [Result<(Data, URLResponse), Error>]
    private(set) var requestCount: Int = 0

    init(queue: [Result<(Data, URLResponse), Error>]) {
        self.queue = queue
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        _ = request
        requestCount += 1

        guard queue.isEmpty == false else {
            throw URLError(.badServerResponse)
        }

        return try queue.removeFirst().get()
    }

    func calls() -> Int {
        requestCount
    }
}

private struct TokenPayload: Decodable {
    let token: String
    let userID: String
    let expiresIn: Int

    enum CodingKeys: String, CodingKey {
        case token
        case userID = "user_id"
        case expiresIn = "expires_in"
    }
}

private func makeResponse(url: URL, statusCode: Int) throws -> HTTPURLResponse {
    guard let response = HTTPURLResponse(
        url: url,
        statusCode: statusCode,
        httpVersion: "HTTP/1.1",
        headerFields: ["Content-Type": "application/json"]
    ) else {
        throw URLError(.badServerResponse)
    }

    return response
}

@Test
func idempotentRequestRetriesAndSucceeds() async throws {
    let baseURL = try #require(URL(string: "https://api.swiftridefood.com"))
    let failingResponse = try makeResponse(url: baseURL.appendingPathComponent("orders"), statusCode: 500)
    let successResponse = try makeResponse(url: baseURL.appendingPathComponent("orders"), statusCode: 200)

    let transport = MockNetworkTransport(queue: [
        .success((Data("{\"message\":\"temporary\"}".utf8), failingResponse)),
        .success((Data("[]".utf8), successResponse))
    ])

    let client = URLSessionHTTPClient(
        baseURL: baseURL,
        transport: transport,
        retryPolicy: RetryPolicy(maxAttempts: 2)
    )

    _ = try await client.send(Endpoint(path: "/orders", method: .get))

    #expect(await transport.calls() == 2)
}

@Test
func nonIdempotentRequestDoesNotRetryOnServerError() async throws {
    let baseURL = try #require(URL(string: "https://api.swiftridefood.com"))
    let response = try makeResponse(url: baseURL.appendingPathComponent("login"), statusCode: 500)

    let transport = MockNetworkTransport(queue: [
        .success((Data("{\"message\":\"boom\"}".utf8), response))
    ])

    let client = URLSessionHTTPClient(
        baseURL: baseURL,
        transport: transport,
        retryPolicy: RetryPolicy(maxAttempts: 2)
    )

    do {
        _ = try await client.send(Endpoint(path: "/login", method: .post))
        Issue.record("Expected request to fail")
    } catch let error as NetworkError {
        #expect(error == .statusCode(code: 500, message: "boom"))
    }

    #expect(await transport.calls() == 1)
}

@Test
func statusCodeErrorMappingUsesServerMessage() async throws {
    let baseURL = try #require(URL(string: "https://api.swiftridefood.com"))
    let response = try makeResponse(url: baseURL.appendingPathComponent("login"), statusCode: 401)

    let transport = MockNetworkTransport(queue: [
        .success((Data("{\"message\":\"Invalid email or password\"}".utf8), response))
    ])

    let client = URLSessionHTTPClient(baseURL: baseURL, transport: transport)

    do {
        _ = try await client.send(Endpoint(path: "/login", method: .post))
        Issue.record("Expected request to fail")
    } catch let error as NetworkError {
        #expect(error.asAppError.errorDescription == "Invalid email or password")
    }
}

@Test
func typedSendDecodesCodableResponse() async throws {
    let baseURL = try #require(URL(string: "https://api.swiftridefood.com"))
    let response = try makeResponse(url: baseURL.appendingPathComponent("login"), statusCode: 200)

    let transport = MockNetworkTransport(queue: [
        .success((Data("{\"token\":\"abc\",\"user_id\":\"u1\",\"expires_in\":3600}".utf8), response))
    ])

    let client = URLSessionHTTPClient(baseURL: baseURL, transport: transport)

    let payload: TokenPayload = try await client.send(Endpoint(path: "/login", method: .post))

    #expect(payload.token == "abc")
    #expect(payload.userID == "u1")
    #expect(payload.expiresIn == 3600)
}

@Test
func typedSendMapsDecodingFailure() async throws {
    let baseURL = try #require(URL(string: "https://api.swiftridefood.com"))
    let response = try makeResponse(url: baseURL.appendingPathComponent("login"), statusCode: 200)

    let transport = MockNetworkTransport(queue: [
        .success((Data("{\"unexpected\":true}".utf8), response))
    ])

    let client = URLSessionHTTPClient(baseURL: baseURL, transport: transport)

    do {
        let _: TokenPayload = try await client.send(Endpoint(path: "/login", method: .post))
        Issue.record("Expected decoding to fail")
    } catch let error as NetworkError {
        #expect(error == .decoding(message: "Failed to decode response"))
    }
}
