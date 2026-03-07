import Foundation
import Security

public enum KeychainTokenStoreError: Error, Equatable, Sendable {
    case saveFailed(status: Int32)
    case readFailed(status: Int32)
    case invalidStoredData
    case deleteFailed(status: Int32)
}

public actor KeychainTokenStore: AuthTokenStoring {
    private let service: String
    private let account: String
    private let backend: any KeychainBackend

    public init(
        service: String,
        account: String,
        backend: any KeychainBackend = SecurityKeychainBackend()
    ) {
        self.service = service
        self.account = account
        self.backend = backend
    }

    public func readToken() async throws -> String? {
        let result = backend.read(service: service, account: account)

        switch result.status {
        case errSecSuccess:
            guard let data = result.data else {
                return nil
            }

            guard let token = String(data: data, encoding: .utf8) else {
                throw KeychainTokenStoreError.invalidStoredData
            }

            return token
        case errSecItemNotFound:
            return nil
        default:
            throw KeychainTokenStoreError.readFailed(status: result.status)
        }
    }

    public func saveToken(_ token: String) async throws {
        guard let data = token.data(using: .utf8) else {
            throw KeychainTokenStoreError.invalidStoredData
        }

        let status = backend.save(data: data, service: service, account: account)

        guard status == errSecSuccess else {
            throw KeychainTokenStoreError.saveFailed(status: status)
        }
    }

    public func clearToken() async throws {
        let status = backend.delete(service: service, account: account)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainTokenStoreError.deleteFailed(status: status)
        }
    }
}
