import Foundation
import Testing
@testable import Networking

@Test
func buildRequestCreatesCorrectURLMethodAndHeaders() throws {
    let baseURL = try #require(URL(string: "https://api.example.com"))
    let builder = HTTPRequestBuilder(baseURL: baseURL)
    let endpoint = Endpoint(
        path: "/orders",
        method: .get,
        queryItems: [URLQueryItem(name: "limit", value: "20")],
        headers: ["Accept": "application/json"]
    )

    let request = try builder.buildRequest(from: endpoint)

    #expect(request.httpMethod == "GET")
    #expect(request.url?.absoluteString == "https://api.example.com/orders?limit=20")
    #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
}
