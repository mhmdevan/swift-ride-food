import Foundation
import Networking

enum APIEndpoints {
    static func login(email: String, password: String) throws -> Endpoint {
        let body = try JSONEncoder.networkDefault.encode(LoginRequestDTO(email: email, password: password))
        return Endpoint(
            path: "/login",
            method: .post,
            headers: [
                "Content-Type": "application/json",
                "Accept": "application/json"
            ],
            body: body
        )
    }

    static func orders() -> Endpoint {
        Endpoint(
            path: "/orders",
            method: .get,
            headers: ["Accept": "application/json"]
        )
    }

    static func order(id: UUID) -> Endpoint {
        Endpoint(
            path: "/orders/\(id.uuidString.lowercased())",
            method: .get,
            headers: ["Accept": "application/json"]
        )
    }
}
