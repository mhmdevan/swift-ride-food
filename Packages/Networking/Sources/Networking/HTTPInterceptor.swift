import Foundation

public protocol HTTPInterceptor: Sendable {
    func adapt(_ request: URLRequest) async throws -> URLRequest
}
