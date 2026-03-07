import Foundation
import Security
import Testing
@testable import FeaturesAuth

private final class MockKeychainBackend: KeychainBackend, @unchecked Sendable {
    var savedData: Data?
    var saveStatus: OSStatus = errSecSuccess
    var readStatus: OSStatus = errSecItemNotFound
    var deleteStatus: OSStatus = errSecSuccess

    func save(data: Data, service: String, account: String) -> OSStatus {
        _ = service
        _ = account
        savedData = data
        readStatus = saveStatus == errSecSuccess ? errSecSuccess : readStatus
        return saveStatus
    }

    func read(service: String, account: String) -> (status: OSStatus, data: Data?) {
        _ = service
        _ = account
        if readStatus == errSecSuccess {
            return (readStatus, savedData)
        }
        return (readStatus, nil)
    }

    func delete(service: String, account: String) -> OSStatus {
        _ = service
        _ = account
        if deleteStatus == errSecSuccess {
            savedData = nil
            readStatus = errSecItemNotFound
        }
        return deleteStatus
    }
}

@Test
func saveThenReadTokenReturnsStoredValue() async throws {
    let backend = MockKeychainBackend()
    let store = KeychainTokenStore(service: "svc", account: "acc", backend: backend)

    try await store.saveToken("token-abc")
    let token = try await store.readToken()

    #expect(token == "token-abc")
}

@Test
func saveTokenThrowsWhenBackendFails() async {
    let backend = MockKeychainBackend()
    backend.saveStatus = errSecParam
    let store = KeychainTokenStore(service: "svc", account: "acc", backend: backend)

    do {
        try await store.saveToken("token-abc")
        Issue.record("Expected save to fail")
    } catch let error as KeychainTokenStoreError {
        #expect(error == .saveFailed(status: errSecParam))
    } catch {
        Issue.record("Unexpected error type: \(error)")
    }
}

@Test
func readTokenThrowsForInvalidUTF8Data() async {
    let backend = MockKeychainBackend()
    backend.savedData = Data([0xD8, 0x00])
    backend.readStatus = errSecSuccess
    let store = KeychainTokenStore(service: "svc", account: "acc", backend: backend)

    do {
        _ = try await store.readToken()
        Issue.record("Expected read to fail")
    } catch let error as KeychainTokenStoreError {
        #expect(error == .invalidStoredData)
    } catch {
        Issue.record("Unexpected error type: \(error)")
    }
}

@Test
func clearTokenAllowsItemNotFoundStatus() async throws {
    let backend = MockKeychainBackend()
    backend.deleteStatus = errSecItemNotFound
    let store = KeychainTokenStore(service: "svc", account: "acc", backend: backend)

    try await store.clearToken()
    #expect(try await store.readToken() == nil)
}
