import Foundation

public struct AuthTokenInterceptor: HTTPInterceptor {
    private let tokenProvider: @Sendable () async -> String?

    public init(tokenProvider: @escaping @Sendable () async -> String?) {
        self.tokenProvider = tokenProvider
    }

    public func adapt(_ request: URLRequest) async throws -> URLRequest {
        guard let token = await tokenProvider(), token.isEmpty == false else {
            return request
        }

        var adaptedRequest = request
        adaptedRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return adaptedRequest
    }
}
