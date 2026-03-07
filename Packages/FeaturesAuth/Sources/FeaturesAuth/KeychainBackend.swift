import Foundation
import Security

public protocol KeychainBackend: Sendable {
    func save(data: Data, service: String, account: String) -> OSStatus
    func read(service: String, account: String) -> (status: OSStatus, data: Data?)
    func delete(service: String, account: String) -> OSStatus
}

public struct SecurityKeychainBackend: KeychainBackend {
    public init() {}

    public func save(data: Data, service: String, account: String) -> OSStatus {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        if status == errSecDuplicateItem {
            let updateQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: account
            ]

            let attributesToUpdate: [String: Any] = [
                kSecValueData as String: data
            ]

            return SecItemUpdate(updateQuery as CFDictionary, attributesToUpdate as CFDictionary)
        }

        return status
    }

    public func read(service: String, account: String) -> (status: OSStatus, data: Data?) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        return (status, item as? Data)
    }

    public func delete(service: String, account: String) -> OSStatus {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        return SecItemDelete(query as CFDictionary)
    }
}
