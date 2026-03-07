public protocol AuthRepository: Sendable {
    func login(email: String, password: String) async throws -> String
}
