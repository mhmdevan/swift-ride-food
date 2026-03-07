import FeaturesAuth
import Foundation

@MainActor
final class SessionViewModel: ObservableObject {
    @Published private(set) var isAuthenticated: Bool = false

    private let tokenStore: any AuthTokenStoring
    private var hasRestored: Bool = false

    init(tokenStore: any AuthTokenStoring) {
        self.tokenStore = tokenStore
    }

    func restoreSessionIfNeeded() async {
        guard hasRestored == false else {
            return
        }

        hasRestored = true

        do {
            let token = try await tokenStore.readToken()
            isAuthenticated = token?.isEmpty == false
        } catch {
            isAuthenticated = false
        }
    }

    func markAuthenticated() {
        isAuthenticated = true
    }

    func markUnauthenticated() {
        isAuthenticated = false
    }
}
