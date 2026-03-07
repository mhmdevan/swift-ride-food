import Foundation

public struct AuthDeepLinkParser: Sendable {
    public init() {}

    public func token(from url: URL) -> String? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }

        guard components.scheme?.lowercased() == "myapp",
              components.host?.lowercased() == "login" else {
            return nil
        }

        return components.queryItems?
            .first(where: { $0.name == "token" })?
            .value
    }
}
