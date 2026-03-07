import Foundation

public protocol NetworkLogger: Sendable {
    func logRequest(_ request: URLRequest, attempt: Int)
    func logResponse(request: URLRequest, response: HTTPURLResponse, data: Data)
    func logError(request: URLRequest, error: Error)
}

public struct NoOpNetworkLogger: NetworkLogger {
    public init() {}

    public func logRequest(_ request: URLRequest, attempt: Int) {
        _ = request
        _ = attempt
    }

    public func logResponse(request: URLRequest, response: HTTPURLResponse, data: Data) {
        _ = request
        _ = response
        _ = data
    }

    public func logError(request: URLRequest, error: Error) {
        _ = request
        _ = error
    }
}

enum NetworkLogSanitizer {
    private static let sensitiveKeyFragments: [String] = [
        "token",
        "password",
        "passcode",
        "email",
        "auth",
        "authorization",
        "secret",
        "api_key",
        "apikey",
        "session"
    ]

    static func redactedURLString(_ url: URL?) -> String {
        guard let url else { return "-" }
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return url.absoluteString
        }

        if let queryItems = components.queryItems, queryItems.isEmpty == false {
            components.queryItems = queryItems.map { item in
                guard isSensitive(name: item.name) else {
                    return item
                }
                return URLQueryItem(name: item.name, value: "REDACTED")
            }
        }

        return components.string ?? url.absoluteString
    }

    private static func isSensitive(name: String) -> Bool {
        let normalized = name.lowercased()
        return sensitiveKeyFragments.contains(where: { normalized.contains($0) })
    }
}

public struct ConsoleNetworkLogger: NetworkLogger {
    public init() {}

    public func logRequest(_ request: URLRequest, attempt: Int) {
#if DEBUG
        let method = request.httpMethod ?? "-"
        let url = NetworkLogSanitizer.redactedURLString(request.url)
        print("[Networking][Request][Attempt \(attempt)] \(method) \(url)")
#endif
    }

    public func logResponse(request: URLRequest, response: HTTPURLResponse, data: Data) {
#if DEBUG
        let method = request.httpMethod ?? "-"
        let url = NetworkLogSanitizer.redactedURLString(request.url)
        print("[Networking][Response] \(method) \(url) status=\(response.statusCode) bytes=\(data.count)")
#endif
    }

    public func logError(request: URLRequest, error: Error) {
#if DEBUG
        let method = request.httpMethod ?? "-"
        let url = NetworkLogSanitizer.redactedURLString(request.url)
        print("[Networking][Error] \(method) \(url) error=\(error)")
#endif
    }
}
