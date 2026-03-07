import Foundation

public protocol AuthTokenStoring: Sendable {
    func readToken() async throws -> String?
    func saveToken(_ token: String) async throws
    func clearToken() async throws
}

public actor InMemoryAuthTokenStore: AuthTokenStoring {
    private var token: String?

    public init(token: String? = nil) {
        self.token = token
    }

    public func readToken() async throws -> String? {
        token
    }

    public func saveToken(_ token: String) async throws {
        self.token = token
    }

    public func clearToken() async throws {
        token = nil
    }
}
