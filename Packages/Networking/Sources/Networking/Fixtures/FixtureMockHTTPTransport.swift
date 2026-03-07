import Foundation

public actor FixtureMockHTTPTransport: NetworkTransport {
    private let fixtureLoader: any FixtureLoading
    private let latencyNanoseconds: UInt64

    public init(
        fixtureLoader: any FixtureLoading = BundleFixtureLoader(),
        latencyNanoseconds: UInt64 = 80_000_000
    ) {
        self.fixtureLoader = fixtureLoader
        self.latencyNanoseconds = latencyNanoseconds
    }

    public func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        guard let url = request.url else {
            throw NetworkError.invalidURL
        }

        if latencyNanoseconds > 0 {
            try await Task.sleep(nanoseconds: latencyNanoseconds)
        }

        let method = request.httpMethod ?? HTTPMethod.get.rawValue

        switch (method, url.path) {
        case (HTTPMethod.post.rawValue, "/login"):
            return try await loginResponse(for: request, url: url)

        case (HTTPMethod.get.rawValue, "/orders"):
            return try response(url: url, statusCode: 200, fixtureName: "orders")

        default:
            if method == HTTPMethod.get.rawValue, url.path.hasPrefix("/orders/") {
                return try await orderDetailsResponse(for: url)
            }
            return try response(url: url, statusCode: 404, fixtureName: "not_found")
        }
    }

    private func loginResponse(for request: URLRequest, url: URL) async throws -> (Data, URLResponse) {
        struct LoginRequestDTO: Decodable {
            let email: String
            let password: String
        }

        guard let body = request.httpBody else {
            return try response(url: url, statusCode: 400, fixtureName: "bad_request")
        }

        let payload = try? JSONDecoder.networkDefault.decode(LoginRequestDTO.self, from: body)

        guard let payload,
              payload.email.contains("@"),
              payload.password == "123456" else {
            return try response(url: url, statusCode: 401, fixtureName: "login_unauthorized")
        }

        return try response(url: url, statusCode: 200, fixtureName: "login_success")
    }

    private func orderDetailsResponse(for url: URL) async throws -> (Data, URLResponse) {
        let identifier = url.lastPathComponent

        let ordersData = try fixtureLoader.loadFixture(named: "orders")
        let decoder = JSONDecoder.networkDefault
        let orders = try decoder.decode([FixtureOrderDTO].self, from: ordersData)

        guard let order = orders.first(where: { $0.id.uuidString.lowercased() == identifier.lowercased() }) else {
            return try response(url: url, statusCode: 404, fixtureName: "not_found")
        }

        let data = try JSONEncoder.networkDefault.encode(order)
        let response = try buildResponse(url: url, statusCode: 200)
        return (data, response)
    }

    private func response(url: URL, statusCode: Int, fixtureName: String) throws -> (Data, URLResponse) {
        let data = try fixtureLoader.loadFixture(named: fixtureName)
        let response = try buildResponse(url: url, statusCode: statusCode)
        return (data, response)
    }

    private func buildResponse(url: URL, statusCode: Int) throws -> HTTPURLResponse {
        guard let response = HTTPURLResponse(
            url: url,
            statusCode: statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"]
        ) else {
            throw NetworkError.invalidResponse
        }

        return response
    }
}

private struct FixtureOrderDTO: Codable {
    let id: UUID
    let title: String
    let status: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case status
        case createdAt = "created_at"
    }
}
