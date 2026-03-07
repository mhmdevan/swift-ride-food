import Core
import Networking

public actor NetworkAuthRepository: AuthRepository {
    private let httpClient: any HTTPClient

    public init(httpClient: any HTTPClient) {
        self.httpClient = httpClient
    }

    public func login(email: String, password: String) async throws -> String {
        do {
            let endpoint = try APIEndpoints.login(email: email, password: password)
            let response: LoginResponseDTO = try await httpClient.send(endpoint)
            return response.token
        } catch let error as NetworkError {
            throw error.asAppError
        } catch {
            throw AppError.unknown
        }
    }
}
