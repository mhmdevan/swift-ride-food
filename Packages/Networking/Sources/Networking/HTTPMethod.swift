public enum HTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"

    public var isIdempotent: Bool {
        switch self {
        case .get, .put, .delete:
            return true
        case .post, .patch:
            return false
        }
    }
}
